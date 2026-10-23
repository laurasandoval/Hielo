import Observation
import SwiftUI

/// A session that preserves the keyboard’s appearance during a presentation.
///
/// Create one session for the screen or navigation flow that uses it. Overlays
/// use the keyboard window while the keyboard is visible and the app window
/// otherwise. Pinning moves a frozen keyboard snapshot into the caller's page
/// while the real keyboard is hidden.
///
/// Store the session in SwiftUI state and attach it to the page with
/// ``View/keyboardFreeze(_:lifecycle:)``. A session manages one presentation
/// at a time; overlay presentation and keyboard pinning are mutually exclusive.
///
/// - Important: Keyboard capture relies on private UIKit behavior. An operation
///   can fail when the required keyboard resources are unavailable. Inspect
///   ``KeyboardFreezeActivationResult`` when using the imperative APIs.
@MainActor
@Observable
public final class KeyboardFreeze {
  /// The geometry available when creating and positioning an overlay.
  ///
  /// All rectangles use the host window’s coordinate space and are measured in points.
  public struct Context: Sendable {
    /// The bounds of the window hosting the overlay.
    public let windowBounds: CGRect
    /// The available safe-area bounds in the host window.
    public let safeAreaBounds: CGRect
    /// The keyboard’s frame in the host window, or zero for an app-window presentation.
    public let keyboardFrame: CGRect
    /// The source view’s frame converted to the host window’s coordinates.
    public let sourceFrame: CGRect
  }

  /// Timing limits for restoring and repinning the live keyboard.
  public struct Configuration: Sendable {
    /// The maximum wait for keyboard restoration before removing the snapshot.
    public var restorationTimeout: Duration
    /// The maximum wait for the keyboard to hide before completing repinning.
    public var repinningTimeout: Duration

    /// Creates a configuration with the specified transition timeouts.
    ///
    /// - Parameters:
    ///   - restorationTimeout: The restoration timeout. The default is one second.
    ///   - repinningTimeout: The repinning timeout. The default is one second.
    public init(
      restorationTimeout: Duration = .seconds(1),
      repinningTimeout: Duration = .seconds(1)
    ) {
      self.restorationTimeout = restorationTimeout
      self.repinningTimeout = repinningTimeout
    }
  }

  /// The current presentation or transition managed by a session.
  public enum Status: Equatable, Sendable {
    /// No presentation is active.
    case idle
    /// An overlay is presented.
    case overlay
    /// A keyboard snapshot is pinned to the page.
    case pinned
    /// The live keyboard is being restored behind the pinned snapshot.
    case restoring
    /// The live keyboard is being hidden while the snapshot remains pinned.
    case repinning
  }

  // MARK: - State

  /// The session’s current presentation state.
  public private(set) var status: Status = .idle

  /// A Boolean value indicating whether an overlay is active.
  public var isPresentingOverlay: Bool {
    status == .overlay
  }

  /// A Boolean value indicating whether a snapshot is pinned, including during restoration or repinning.
  public var isPinned: Bool {
    switch status {
    case .pinned, .restoring, .repinning:
      true
    case .idle, .overlay:
      false
    }
  }

  /// The pinned keyboard’s height in points, or zero when no snapshot is pinned.
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

  /// Creates a session for managing keyboard presentations.
  ///
  /// - Parameter configuration: Transition timing limits. The default uses a
  ///   one-second timeout for restoration and repinning.
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

  /// Presents custom content over a snapshot of the live keyboard.
  ///
  /// Attach the source with ``View/keyboardFreezeSource(_:)`` before calling
  /// this method. Keep the original input focused during presentation.
  /// A live keyboard is required; this method does not fall back to the app window.
  ///
  /// - Parameters:
  ///   - source: The view whose position anchors the overlay.
  ///   - overlayFrame: A closure returning the overlay’s frame in host-window
  ///     coordinates. By default, the overlay covers the keyboard frame.
  ///   - onOutsideTap: An action for taps outside the overlay. The default,
  ///     `nil`, dismisses the overlay. A supplied action replaces that behavior.
  ///   - content: A closure creating the overlay from its geometry context.
  /// - Returns: The activation result, including the reason presentation failed.
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

  /// Presents a keyboard overlay using an explicit source frame.
  ///
  /// Use this overload when you already know the source’s screen coordinates.
  /// A live keyboard is required. Keep the original input focused while the
  /// overlay is presented.
  ///
  /// - Parameters:
  ///   - sourceFrame: The source rectangle in screen coordinates. The default
  ///     is zero. The context converts it to host-window coordinates.
  ///   - overlayFrame: A closure returning a frame in host-window coordinates.
  ///     By default, the overlay covers the keyboard frame.
  ///   - onOutsideTap: An action for outside taps, or `nil` to dismiss the overlay.
  ///   - content: A closure creating the overlay from its geometry context.
  /// - Returns: The result of attempting to start the presentation.
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

  /// Dismisses the active overlay after an optional delay.
  ///
  /// Use a delay to allow your content’s dismissal animation to finish. A later
  /// dismissal request replaces a pending one. Cancellation of the session also
  /// cancels a pending dismissal and its completion.
  ///
  /// - Parameters:
  ///  - delay: The time to wait before removing the overlay. The default is zero.
  ///  - completion: The action to perform after removal, or immediately if no
  ///    overlay is active. The default is `nil`.
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

  /// Pins a snapshot of the live keyboard to the hosting page.
  ///
  /// Apply ``View/keyboardFreeze(_:lifecycle:)`` to the page first. The session
  /// mounts the snapshot before asking the input to resign focus. Calling this
  /// during restoration keeps the snapshot and begins repinning instead.
  ///
  /// - Parameter resignFirstResponder: An action that removes input focus,
  ///   for example by setting its focus binding to `false`.
  /// - Returns: The activation result. An overlay blocks pinning, and an
  ///   unavailable keyboard prevents a new snapshot from being captured.
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

  /// Restores the live keyboard behind a pinned snapshot.
  ///
  /// The snapshot remains visible until restoration completes or times out.
  /// If the session is idle, the focus action runs immediately. During repinning,
  /// restoration is queued; during an overlay or existing restoration, this call
  /// has no effect.
  ///
  /// - Parameter focusFirstResponder: An action that focuses the original input,
  ///   for example by setting its focus binding to `true`.
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

  /// Removes the pinned keyboard snapshot without restoring input focus.
  ///
  /// This method also cancels a pending restoration or repinning transition.
  /// It has no effect when no snapshot is pinned.
  public func unpin() {
    guard isPinned else { return }
    cancel()
  }

  /// Ends the active presentation and cancels pending transitions.
  ///
  /// Use this method when the session is no longer needed. It removes overlays
  /// and pinned snapshots, restores window state, and returns the session to idle.
  /// It does not request input focus. Calling it on an idle session has no effect.
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
