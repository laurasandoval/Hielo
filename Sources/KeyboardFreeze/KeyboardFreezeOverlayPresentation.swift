import SwiftUI

@MainActor
final class KeyboardFreezeOverlayPresentation: NSObject, UIGestureRecognizerDelegate {
  private let onOutsideTap: @MainActor () -> Void
  private let presentationView: KeyboardFreezePresentationView
  private let hostingController: UIHostingController<AnyView>

  init(
    hostWindow: UIWindow,
    backgroundView: UIView? = nil,
    backgroundFrame: CGRect = .zero,
    overlayFrame: CGRect,
    onOutsideTap: @escaping @MainActor () -> Void,
    content: AnyView
  ) {
    self.onOutsideTap = onOutsideTap
    presentationView = KeyboardFreezePresentationView(onDismiss: onOutsideTap)
    hostingController = UIHostingController(rootView: content)
    super.init()

    presentationView.backgroundColor = .clear
    presentationView.frame = hostWindow.bounds
    presentationView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    presentationView.accessibilityViewIsModal = true

    if let backgroundView {
      backgroundView.frame = backgroundFrame
      backgroundView.isUserInteractionEnabled = false
      backgroundView.accessibilityElementsHidden = true
      presentationView.addSubview(backgroundView)
    }

    hostingController.view.backgroundColor = .clear
    hostingController.view.frame = overlayFrame
    presentationView.addSubview(hostingController.view)

    presentationView.addGestureRecognizer(makeOutsideTapRecognizer())
    hostWindow.addSubview(presentationView)
  }

  func tearDown() {
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
    return !hostingController.view.point(inside: location, with: nil)
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

}
