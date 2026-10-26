import SwiftUI

extension HieloSession {
  @discardableResult
  func presentAdaptiveOverlay<Content: View>(
    id: UUID,
    onEnded: @escaping @MainActor () -> Void,
    from source: HieloSource,
    sourceFrame: CGRect,
    overlayFrame: (Context) -> CGRect,
    onOutsideTap: (@MainActor () -> Void)? = nil,
    @ViewBuilder content: (Context) -> Content
  ) -> HieloActivationResult {
    guard case .idle = storage else {
      return .blockedByActivePresentation(status)
    }

    let sourceWindowResolution = source.resolveWindow()
    if let capture = runtime.capture() {
      return startOverlayPresentation(
        id: id,
        onEnded: onEnded,
        capture: capture,
        sourceWindow: sourceWindowResolution?.window,
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
      id: id,
      onEnded: onEnded,
      resolution: sourceWindowResolution,
      overlayFrame: overlayFrame,
      onOutsideTap: onOutsideTap,
      content: { AnyView(content($0)) }
    )
  }

  private func startOverlayPresentation(
    id: UUID = UUID(),
    onEnded: (@MainActor () -> Void)? = nil,
    capture: HieloRuntime.Capture,
    sourceWindow: UIWindow? = nil,
    sourceFrame: CGRect,
    safeAreaFrameInScreen: CGRect? = nil,
    overlayFrame: (Context) -> CGRect,
    onOutsideTap: (@MainActor () -> Void)?,
    content: (Context) -> AnyView
  ) -> HieloActivationResult {
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
    let presentation = HieloOverlayPresentation(
      id: id,
      onEnded: onEnded,
      hostWindow: keyboardWindow,
      sourceWindow: sourceWindow ?? keyboardWindow.windowScene?.windows.first {
        $0 !== keyboardWindow && $0.isKeyWindow
      },
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
    id: UUID = UUID(),
    onEnded: (@MainActor () -> Void)? = nil,
    resolution: HieloSource.WindowResolution,
    overlayFrame: (Context) -> CGRect,
    onOutsideTap: (@MainActor () -> Void)?,
    content: (Context) -> AnyView
  ) -> HieloActivationResult {
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
    let presentation = HieloOverlayPresentation(
      id: id,
      onEnded: onEnded,
      hostWindow: hostWindow,
      overlayFrame: overlayFrame(context),
      onOutsideTap: outsideTapAction,
      content: content(context)
    )
    setStorage(.overlay(presentation))
    return .started
  }

  func finishOverlayPresentation(
    _ presentation: HieloOverlayPresentation
  ) {
    guard case .overlay(let currentPresentation) = storage,
      currentPresentation === presentation
    else { return }

    setStorage(.idle)
    presentation.tearDown()
  }

  // Identity checks keep callbacks from an old host from affecting a new overlay.
  func updateOverlayFrame(_ frame: CGRect, id: UUID) {
    guard case .overlay(let presentation) = storage, presentation.id == id else { return }
    presentation.updateFrame(frame)
  }

  func dismissOverlay(id: UUID) {
    guard case .overlay(let presentation) = storage, presentation.id == id else { return }
    finishOverlayPresentation(presentation)
  }
}
