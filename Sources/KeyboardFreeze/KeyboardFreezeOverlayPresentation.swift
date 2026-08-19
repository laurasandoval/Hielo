import SwiftUI

@MainActor
final class KeyboardFreezeOverlayPresentation: NSObject, UIGestureRecognizerDelegate {
  private let onOutsideTap: @MainActor () -> Void
  private let overlayFrame: CGRect
  private let presentationView: KeyboardFreezePresentationView
  private let hostingController: UIHostingController<AnyView>
  private var overlayWindow: KeyboardFreezeOverlayWindow?

  init(
    keyboardWindow: UIWindow,
    keyboardSnapshotView: UIView,
    keyboardFrame: CGRect,
    overlayFrame: CGRect,
    onOutsideTap: @escaping @MainActor () -> Void,
    content: AnyView
  ) {
    let applicationKeyWindow = Self.applicationKeyWindow(
      on: keyboardWindow.screen
    )
    let presentedOverlayFrame: CGRect
    if let applicationKeyWindow {
      let frameInScreen = keyboardWindow.convert(overlayFrame, to: nil)
      presentedOverlayFrame = applicationKeyWindow.convert(
        frameInScreen,
        from: nil
      )
    } else {
      presentedOverlayFrame = overlayFrame
    }

    self.onOutsideTap = onOutsideTap
    self.overlayFrame = presentedOverlayFrame
    presentationView = KeyboardFreezePresentationView(onDismiss: onOutsideTap)
    hostingController = UIHostingController(
      rootView: AnyView(
        ZStack(alignment: .topLeading) {
          content
            .frame(
              width: presentedOverlayFrame.width,
              height: presentedOverlayFrame.height
            )
            .offset(
              x: presentedOverlayFrame.minX,
              y: presentedOverlayFrame.minY
            )
        }
        .frame(
          width: keyboardWindow.bounds.width,
          height: keyboardWindow.bounds.height,
          alignment: .topLeading
        )
      )
    )
    super.init()

    presentationView.backgroundColor = .clear
    presentationView.frame = keyboardWindow.bounds
    presentationView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    presentationView.accessibilityViewIsModal = true

    keyboardSnapshotView.frame = keyboardFrame
    keyboardSnapshotView.isUserInteractionEnabled = false
    keyboardSnapshotView.accessibilityElementsHidden = true
    presentationView.addSubview(keyboardSnapshotView)

    hostingController.view.backgroundColor = .clear
    if let windowScene = applicationKeyWindow?.windowScene {
      let overlayWindow = KeyboardFreezeOverlayWindow(windowScene: windowScene)
      overlayWindow.backgroundColor = .clear
      overlayWindow.windowLevel = keyboardWindow.windowLevel + 1
      overlayWindow.rootViewController = hostingController

      self.overlayWindow = overlayWindow
      overlayWindow.isHidden = false
    } else {
      hostingController.view.frame = keyboardWindow.bounds
      presentationView.addSubview(hostingController.view)
    }

    hostingController.view.addGestureRecognizer(makeOutsideTapRecognizer())
    if overlayWindow != nil {
      presentationView.addGestureRecognizer(makeOutsideTapRecognizer())
    }
    keyboardWindow.addSubview(presentationView)
  }

  func tearDown() {
    hostingController.view.removeFromSuperview()
    overlayWindow?.isHidden = true
    overlayWindow?.rootViewController = nil
    overlayWindow = nil
    presentationView.removeFromSuperview()
  }

  func notifyOutsideTap() {
    onOutsideTap()
  }

  func gestureRecognizer(
    _: UIGestureRecognizer,
    shouldReceive touch: UITouch
  ) -> Bool {
    let location = touch.location(in: hostingController.view)
    return !overlayFrame.contains(location)
  }

  @objc private func handleOutsideTap(_: UITapGestureRecognizer) {
    notifyOutsideTap()
  }

  private func makeOutsideTapRecognizer() -> UITapGestureRecognizer {
    let recognizer = UITapGestureRecognizer(
      target: self,
      action: #selector(handleOutsideTap)
    )
    recognizer.cancelsTouchesInView = true
    recognizer.delegate = self
    return recognizer
  }

  private static func applicationKeyWindow(on screen: UIScreen) -> UIWindow? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .filter {
        $0.activationState == .foregroundActive
          && $0.session.role == .windowApplication
          && $0.screen === screen
      }
      .flatMap(\.windows)
      .first(where: \.isKeyWindow)
  }
}
