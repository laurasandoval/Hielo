import Observation
import SwiftUI

/// Owns one frozen-keyboard presentation at a time.
///
/// Create one session for the screen or navigation flow that uses it. Overlays
/// use the keyboard window while the keyboard is visible and the app window
/// otherwise. Pinning moves a frozen keyboard snapshot into the caller's page
/// while the real keyboard is hidden.
@MainActor
@Observable
public final class KeyboardFreeze {
  public struct Context: Sendable {
    public let windowBounds: CGRect
    public let safeAreaBounds: CGRect
    public let keyboardFrame: CGRect
    public let sourceFrame: CGRect
  }

  public struct Configuration: Sendable {
    public var restorationTimeout: Duration
    public var repinningTimeout: Duration

    public init(
      restorationTimeout: Duration = .seconds(1),
      repinningTimeout: Duration = .seconds(1)
    ) {
      self.restorationTimeout = restorationTimeout
      self.repinningTimeout = repinningTimeout
    }
  }

  public enum Status: Equatable, Sendable {
    case idle
    case overlay
    case pinned
    case restoring
    case repinning
  }

  // MARK: - State

  public private(set) var status: Status = .idle

  public var isPresentingOverlay: Bool {
    status == .overlay
  }

  public var isPinned: Bool {
    switch status {
    case .pinned, .restoring, .repinning:
      true
    case .idle, .overlay:
      false
    }
  }

  public var pinnedKeyboardHeight: CGFloat {
    activePin?.keyboardFrameInScreen.height ?? 0
  }

  @ObservationIgnored private let configuration: Configuration
  @ObservationIgnored private let runtime: any KeyboardFreezeRuntimeProviding
  @ObservationIgnored private let notificationCenter: NotificationCenter
  @ObservationIgnored private var storage = Storage.idle
  @ObservationIgnored private var overlayDismissalTask: Task<Void, Never>?
  @ObservationIgnored private var keyboardTransitionTask: Task<Void, Never>?
  @ObservationIgnored private var transitionTimeoutTask: Task<Void, Never>?
  @ObservationIgnored private var keyboardWillShowObserver: NSObjectProtocol?
  @ObservationIgnored private var keyboardDidShowObserver: NSObjectProtocol?
  @ObservationIgnored private var keyboardDidHideObserver: NSObjectProtocol?
  @ObservationIgnored private var animationSuppressionID: UUID?
  @ObservationIgnored private var animationsWereEnabledBeforeSuppression: Bool?

  // MARK: - Lifecycle

  public convenience init(configuration: Configuration = Configuration()) {
    self.init(
      configuration: configuration,
      runtime: LiveKeyboardFreezeRuntime(),
      notificationCenter: .default
    )
  }

  init(
    configuration: Configuration,
    runtime: any KeyboardFreezeRuntimeProviding,
    notificationCenter: NotificationCenter
  ) {
    self.configuration = configuration
    self.runtime = runtime
    self.notificationCenter = notificationCenter
  }

  deinit {
    MainActor.assumeIsolated {
      cancel()
    }
  }

  // MARK: - Overlay presentation

  /// Mounts custom SwiftUI content over a frozen snapshot of the keyboard.
  ///
  /// Keep the original input focused while this presentation is active.
  @discardableResult
  public func presentOverlay<Content: View>(
    from source: KeyboardFreezeSource,
    overlayFrame: (Context) -> CGRect = { $0.keyboardFrame },
    onOutsideTap: (@MainActor () -> Void)? = nil,
    @ViewBuilder content: (Context) -> Content
  ) -> KeyboardFreezeActivationResult {
    presentOverlayFromSourceErased(
      source: source,
      overlayFrame: overlayFrame,
      onOutsideTap: onOutsideTap,
      content: { AnyView(content($0)) }
    )
  }

  @discardableResult
  func presentAdaptiveOverlay<Content: View>(
    from source: KeyboardFreezeSource,
    sourceFrame: CGRect,
    overlayFrame: (Context) -> CGRect,
    onOutsideTap: (@MainActor () -> Void)? = nil,
    @ViewBuilder content: (Context) -> Content
  ) -> KeyboardFreezeActivationResult {
    guard case .idle = storage else {
      return .blockedByActivePresentation(status)
    }

    let sourceWindowResolution = source.resolveWindow()
    if let capture = runtime.capture() {
      return startOverlayPresentation(
        capture: capture,
        sourceFrame: sourceFrame,
        safeAreaFrameInScreen: sourceWindowResolution?.safeAreaFrameInScreen,
        overlayFrame: overlayFrame,
        onOutsideTap: onOutsideTap,
        content: { AnyView(content($0)) }
      )
    }

    guard let sourceWindowResolution else {
      return .sourceUnavailable
    }
    return startScreenOverlayPresentation(
      resolution: sourceWindowResolution,
      overlayFrame: overlayFrame,
      onOutsideTap: onOutsideTap,
      content: { AnyView(content($0)) }
    )
  }

  /// Mounts custom SwiftUI content using explicit screen coordinates.
  @discardableResult
  public func presentOverlay<Content: View>(
    sourceFrame: CGRect = .zero,
    overlayFrame: (Context) -> CGRect = { $0.keyboardFrame },
    onOutsideTap: (@MainActor () -> Void)? = nil,
    @ViewBuilder content: (Context) -> Content
  ) -> KeyboardFreezeActivationResult {
    presentOverlayErased(
      sourceFrame: sourceFrame,
      overlayFrame: overlayFrame,
      onOutsideTap: onOutsideTap,
      content: { AnyView(content($0)) }
    )
  }

  /// Dismisses the active overlay immediately or after an animation delay.
  public func dismissOverlay(
    after delay: Duration = .zero,
    completion: (@MainActor () -> Void)? = nil
  ) {
    guard case .overlay(let presentation) = storage else {
      completion?()
      return
    }

    overlayDismissalTask?.cancel()
    guard delay > .zero else {
      finishOverlayPresentation(presentation)
      completion?()
      return
    }

    overlayDismissalTask = Task { @MainActor [weak self] in
      try? await Task.sleep(for: delay)
      guard !Task.isCancelled, let self else { return }
      guard case .overlay(let currentPresentation) = storage,
        currentPresentation === presentation
      else { return }

      finishOverlayPresentation(presentation)
      completion?()
    }
  }

  // MARK: - Keyboard pinning

  /// Captures the live keyboard, mounts it in the moving page, and resigns focus.
  ///
  /// Calling this while restoration is in flight interrupts that restoration
  /// and keeps the existing frozen snapshot mounted.
  @discardableResult
  public func pinKeyboard(
    resigningFirstResponder resignFirstResponder: @escaping @MainActor () -> Void
  ) -> KeyboardFreezeActivationResult {
    switch storage {
    case .pinned:
      return .alreadyActive
    case .restoring(let pin, let presentation):
      beginRepinning(
        pin: pin,
        presentation: presentation,
        resignFirstResponder: resignFirstResponder
      )
      return .started
    case .repinning:
      resignWithoutAnimationAcrossNextTurn(resignFirstResponder)
      return .alreadyActive
    case .overlay:
      return .blockedByActivePresentation(status)
    case .idle:
      break
    }

    guard let capture = runtime.capture() else {
      return .keyboardUnavailable
    }

    runtime.pauseSnapshot(capture.snapshotView)
    capture.snapshotView.isUserInteractionEnabled = false
    let pin = KeyboardFreezePin(capture: capture)
    setStorage(.pinned(pin))

    keyboardTransitionTask?.cancel()
    keyboardTransitionTask = Task { @MainActor [weak self] in
      await Task.yield()
      guard let self else { return }
      guard case .pinned(let currentPin) = storage, currentPin === pin else {
        return
      }
      resignWithoutAnimationAcrossNextTurn(resignFirstResponder)
    }
    return .started
  }

  // MARK: - Keyboard restoration

  /// Restores focus behind the snapshot, then reveals the live keyboard at once.
  public func restoreKeyboard(
    focusingFirstResponder focusFirstResponder: @escaping @MainActor () -> Void
  ) {
    switch storage {
    case .pinned(let pin):
      beginRestoring(pin: pin, focusFirstResponder: focusFirstResponder)
    case .repinning(let pin, let presentation, _):
      storage = .repinning(
        pin,
        presentation,
        pendingFocus: focusFirstResponder
      )
    case .idle:
      focusFirstResponder()
    case .overlay, .restoring:
      break
    }
  }

  /// Removes a pinned snapshot without restoring focus.
  public func unpin() {
    guard isPinned else { return }
    cancel()
  }

  /// Immediately removes every presentation and restores external UIKit state.
  public func cancel() {
    let previousStatus = status
    cancelTasksAndObservers()

    switch storage {
    case .idle:
      break
    case .overlay(let presentation):
      presentation.tearDown()
    case .pinned(let pin):
      pin.snapshotView.removeFromSuperview()
    case .restoring(let pin, let presentation),
      .repinning(let pin, let presentation, _):
      presentation.tearDown()
      pin.snapshotView.removeFromSuperview()
    }
    storage = .idle
    if previousStatus != .idle {
      status = .idle
    }
  }

  // MARK: - Host integration

  func layoutPageSnapshot(in container: UIView) {
    guard let snapshotView = pageSnapshotView, let pin = activePin else {
      for subview in container.subviews {
        subview.removeFromSuperview()
      }
      return
    }

    if snapshotView.superview !== container {
      snapshotView.removeFromSuperview()
      container.addSubview(snapshotView)
    }

    let screenBottomGap = max(
      0,
      pin.keyboardWindow.screen.bounds.maxY - pin.keyboardFrameInScreen.maxY
    )
    snapshotView.frame = CGRect(
      x: pin.keyboardFrameInScreen.minX,
      y: -screenBottomGap,
      width: pin.keyboardFrameInScreen.width,
      height: pin.keyboardFrameInScreen.height
    )
  }

  func handleOutsideOverlayTap() {
    guard case .overlay(let presentation) = storage else { return }
    presentation.notifyOutsideTap()
  }

  private var activePin: KeyboardFreezePin? {
    switch storage {
    case .pinned(let pin),
      .restoring(let pin, _),
      .repinning(let pin, _, _):
      pin
    case .idle, .overlay:
      nil
    }
  }

  private var pageSnapshotView: UIView? {
    activePin?.snapshotView
  }

  // MARK: - Overlay internals

  private func presentOverlayErased(
    sourceFrame: CGRect,
    overlayFrame: (Context) -> CGRect,
    onOutsideTap: (@MainActor () -> Void)?,
    content: (Context) -> AnyView
  ) -> KeyboardFreezeActivationResult {
    guard case .idle = storage else {
      return .blockedByActivePresentation(status)
    }
    guard let capture = runtime.capture() else {
      return .keyboardUnavailable
    }
    return startOverlayPresentation(
      capture: capture,
      sourceFrame: sourceFrame,
      overlayFrame: overlayFrame,
      onOutsideTap: onOutsideTap,
      content: content
    )
  }

  private func presentOverlayFromSourceErased(
    source: KeyboardFreezeSource,
    overlayFrame: (Context) -> CGRect,
    onOutsideTap: (@MainActor () -> Void)?,
    content: (Context) -> AnyView
  ) -> KeyboardFreezeActivationResult {
    guard case .idle = storage else {
      return .blockedByActivePresentation(status)
    }
    guard let capture = runtime.capture() else {
      return .keyboardUnavailable
    }
    guard let sourceFrame = source.resolveFrame(on: capture.keyboardWindow.screen) else {
      return .sourceUnavailable
    }

    return startOverlayPresentation(
      capture: capture,
      sourceFrame: sourceFrame,
      overlayFrame: overlayFrame,
      onOutsideTap: onOutsideTap,
      content: content
    )
  }

  private func startOverlayPresentation(
    capture: KeyboardFreezeRuntime.Capture,
    sourceFrame: CGRect,
    safeAreaFrameInScreen: CGRect? = nil,
    overlayFrame: (Context) -> CGRect,
    onOutsideTap: (@MainActor () -> Void)?,
    content: (Context) -> AnyView
  ) -> KeyboardFreezeActivationResult {
    let keyboardWindow = capture.keyboardWindow
    let outsideTapAction =
      onOutsideTap ?? { [weak self] in
        self?.dismissOverlay()
      }
    let context = Context(
      windowBounds: keyboardWindow.bounds,
      safeAreaBounds: safeAreaFrameInScreen.map {
        keyboardWindow.convert($0, from: nil)
      } ?? keyboardWindow.bounds.inset(by: keyboardWindow.safeAreaInsets),
      keyboardFrame: capture.keyboardFrameInWindow,
      sourceFrame: keyboardWindow.convert(sourceFrame, from: nil)
    )
    runtime.pauseSnapshot(capture.snapshotView)
    let presentation = KeyboardFreezeOverlayPresentation(
      hostWindow: keyboardWindow,
      backgroundView: capture.snapshotView,
      backgroundFrame: context.keyboardFrame,
      overlayFrame: overlayFrame(context),
      onOutsideTap: outsideTapAction,
      content: content(context)
    )
    setStorage(.overlay(presentation))
    return .started
  }

  private func startScreenOverlayPresentation(
    resolution: KeyboardFreezeSource.WindowResolution,
    overlayFrame: (Context) -> CGRect,
    onOutsideTap: (@MainActor () -> Void)?,
    content: (Context) -> AnyView
  ) -> KeyboardFreezeActivationResult {
    let hostWindow = resolution.window
    let outsideTapAction =
      onOutsideTap ?? { [weak self] in
        self?.dismissOverlay()
      }
    let context = Context(
      windowBounds: hostWindow.bounds,
      safeAreaBounds: hostWindow.convert(resolution.safeAreaFrameInScreen, from: nil),
      keyboardFrame: .zero,
      sourceFrame: hostWindow.convert(resolution.frameInScreen, from: nil)
    )
    let presentation = KeyboardFreezeOverlayPresentation(
      hostWindow: hostWindow,
      overlayFrame: overlayFrame(context),
      onOutsideTap: outsideTapAction,
      content: content(context)
    )
    setStorage(.overlay(presentation))
    return .started
  }

  private func finishOverlayPresentation(
    _ presentation: KeyboardFreezeOverlayPresentation
  ) {
    guard case .overlay(let currentPresentation) = storage,
      currentPresentation === presentation
    else { return }

    overlayDismissalTask = nil
    presentation.tearDown()
    setStorage(.idle)
  }

  // MARK: - Restoration internals

  private func beginRestoring(
    pin: KeyboardFreezePin,
    focusFirstResponder: @escaping @MainActor () -> Void
  ) {
    keyboardTransitionTask?.cancel()
    let presentation = KeyboardFreezeRestorationPresentation(
      pin: pin,
      runtime: runtime
    )
    setStorage(.restoring(pin, presentation))
    installKeyboardShowObservers(for: presentation)
    focusFirstResponder()

    startTransitionTimeout(configuration.restorationTimeout) {
      [weak self, weak presentation] in
      guard let self, let presentation else { return }
      finishKeyboardRestoration(presentation)
    }
  }

  private func beginRepinning(
    pin: KeyboardFreezePin,
    presentation: KeyboardFreezeRestorationPresentation,
    resignFirstResponder: @escaping @MainActor () -> Void
  ) {
    transitionTimeoutTask?.cancel()
    removeKeyboardShowObservers()
    setStorage(.repinning(pin, presentation, pendingFocus: nil))
    installKeyboardDidHideObserver(for: presentation)
    resignWithoutAnimationAcrossNextTurn(resignFirstResponder)

    startTransitionTimeout(configuration.repinningTimeout) {
      [weak self, weak presentation] in
      guard let self, let presentation else { return }
      finishRepinning(presentation)
    }
  }

  private func finishKeyboardRestoration(
    _ presentation: KeyboardFreezeRestorationPresentation
  ) {
    guard case .restoring(let pin, let currentPresentation) = storage,
      currentPresentation === presentation
    else { return }

    transitionTimeoutTask?.cancel()
    transitionTimeoutTask = nil
    removeKeyboardShowObservers()
    presentation.tearDown()
    pin.snapshotView.removeFromSuperview()
    setStorage(.idle)
  }

  private func finishRepinning(
    _ presentation: KeyboardFreezeRestorationPresentation
  ) {
    guard case .repinning(let pin, let currentPresentation, let pendingFocus) = storage,
      currentPresentation === presentation
    else { return }

    transitionTimeoutTask?.cancel()
    transitionTimeoutTask = nil
    removeKeyboardDidHideObserver()
    presentation.tearDown()
    setStorage(.pinned(pin))

    if let pendingFocus {
      beginRestoring(pin: pin, focusFirstResponder: pendingFocus)
    }
  }

  // MARK: - Keyboard lifecycle

  private func installKeyboardShowObservers(
    for presentation: KeyboardFreezeRestorationPresentation
  ) {
    removeKeyboardShowObservers()
    keyboardWillShowObserver = notificationCenter.addObserver(
      forName: UIResponder.keyboardWillShowNotification,
      object: nil,
      queue: .main
    ) { [weak self, weak presentation] _ in
      Task { @MainActor in
        guard let self, let presentation else { return }
        guard case .restoring(_, let currentPresentation) = self.storage,
          currentPresentation === presentation
        else { return }
        presentation.hideKeyboardWindows()
      }
    }
    keyboardDidShowObserver = notificationCenter.addObserver(
      forName: UIResponder.keyboardDidShowNotification,
      object: nil,
      queue: .main
    ) { [weak self, weak presentation] _ in
      Task { @MainActor in
        guard let self, let presentation else { return }
        self.finishKeyboardRestoration(presentation)
      }
    }
  }

  private func installKeyboardDidHideObserver(
    for presentation: KeyboardFreezeRestorationPresentation
  ) {
    removeKeyboardDidHideObserver()
    keyboardDidHideObserver = notificationCenter.addObserver(
      forName: UIResponder.keyboardDidHideNotification,
      object: nil,
      queue: .main
    ) { [weak self, weak presentation] _ in
      Task { @MainActor in
        guard let self, let presentation else { return }
        self.finishRepinning(presentation)
      }
    }
  }

  private func startTransitionTimeout(
    _ duration: Duration,
    action: @escaping @MainActor () -> Void
  ) {
    transitionTimeoutTask?.cancel()
    transitionTimeoutTask = Task { @MainActor in
      try? await Task.sleep(for: duration)
      guard !Task.isCancelled else { return }
      action()
    }
  }

  private func resignWithoutAnimationAcrossNextTurn(
    _ resignFirstResponder: @escaping @MainActor () -> Void
  ) {
    keyboardTransitionTask?.cancel()
    let suppressionID = UUID()
    if animationSuppressionID == nil {
      animationsWereEnabledBeforeSuppression = UIView.areAnimationsEnabled
    }
    animationSuppressionID = suppressionID
    UIView.setAnimationsEnabled(false)
    resignFirstResponder()

    keyboardTransitionTask = Task { @MainActor [weak self] in
      await Task.yield()
      self?.finishAnimationSuppression(suppressionID)
    }
  }

  private func finishAnimationSuppression(_ suppressionID: UUID? = nil) {
    if let suppressionID, animationSuppressionID != suppressionID {
      return
    }
    guard let animationsWereEnabledBeforeSuppression else { return }
    UIView.setAnimationsEnabled(animationsWereEnabledBeforeSuppression)
    animationSuppressionID = nil
    self.animationsWereEnabledBeforeSuppression = nil
  }

  // MARK: - Cleanup

  private func cancelTasksAndObservers() {
    overlayDismissalTask?.cancel()
    overlayDismissalTask = nil
    keyboardTransitionTask?.cancel()
    keyboardTransitionTask = nil
    finishAnimationSuppression()
    transitionTimeoutTask?.cancel()
    transitionTimeoutTask = nil
    removeKeyboardShowObservers()
    removeKeyboardDidHideObserver()
  }

  private func removeKeyboardShowObservers() {
    if let keyboardWillShowObserver {
      notificationCenter.removeObserver(keyboardWillShowObserver)
      self.keyboardWillShowObserver = nil
    }
    if let keyboardDidShowObserver {
      notificationCenter.removeObserver(keyboardDidShowObserver)
      self.keyboardDidShowObserver = nil
    }
  }

  private func removeKeyboardDidHideObserver() {
    guard let keyboardDidHideObserver else { return }
    notificationCenter.removeObserver(keyboardDidHideObserver)
    self.keyboardDidHideObserver = nil
  }

  private func setStorage(_ storage: Storage) {
    self.storage = storage
    status = storage.status
  }

  // MARK: - Storage

  private enum Storage {
    case idle
    case overlay(KeyboardFreezeOverlayPresentation)
    case pinned(KeyboardFreezePin)
    case restoring(KeyboardFreezePin, KeyboardFreezeRestorationPresentation)
    case repinning(
      KeyboardFreezePin,
      KeyboardFreezeRestorationPresentation,
      pendingFocus: (@MainActor () -> Void)?
    )

    var status: Status {
      switch self {
      case .idle:
        .idle
      case .overlay:
        .overlay
      case .pinned:
        .pinned
      case .restoring:
        .restoring
      case .repinning:
        .repinning
      }
    }
  }
}
