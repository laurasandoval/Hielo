import SwiftUI

@MainActor
final class HieloOverlayPresentation: NSObject, UIGestureRecognizerDelegate {
  let id: UUID
  private var onEnded: (@MainActor () -> Void)?
  private let onOutsideTap: @MainActor () -> Void
  private let presentationView: HieloPresentationView
  private var appInteractionShield: UIControl?
  private let hostingController: UIHostingController<AnyView>
  private var keyboardHideObserver: (any NSObjectProtocol)?

  /// Called when the keyboard that hosts this presentation is dismissed.
  var onKeyboardDismissed: (@MainActor () -> Void)?

  init(
    id: UUID = UUID(),
    onEnded: (@MainActor () -> Void)? = nil,
    hostWindow: UIWindow,
    sourceWindow: UIWindow? = nil,
    backgroundView: UIView? = nil,
    backgroundFrame: CGRect = .zero,
    overlayFrame: CGRect,
    onOutsideTap: @escaping @MainActor () -> Void,
    content: AnyView
  ) {
    self.id = id
    self.onEnded = onEnded
    self.onOutsideTap = onOutsideTap
    presentationView = HieloPresentationView(onDismiss: onOutsideTap)
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

      // The keyboard window stops rendering once its keyboard is gone, so an
      // in-flight collapse animation there may never report completion.
      keyboardHideObserver = NotificationCenter.default.addObserver(
        forName: UIResponder.keyboardDidHideNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        MainActor.assumeIsolated {
          self?.onKeyboardDismissed?()
        }
      }
    }

    hostingController.view.backgroundColor = .clear
    hostingController.view.frame = overlayFrame
    presentationView.addSubview(hostingController.view)

    presentationView.addGestureRecognizer(makeOutsideTapRecognizer())
    hostWindow.addSubview(presentationView)

    // The keyboard host cannot intercept taps on the app's navigation controls.
    if let sourceWindow, sourceWindow !== hostWindow {
      let shield = UIControl(frame: sourceWindow.bounds)
      shield.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      shield.accessibilityElementsHidden = true
      shield.addTarget(self, action: #selector(handleAppOutsideTap), for: .touchUpInside)
      sourceWindow.addSubview(shield)
      appInteractionShield = shield
    }
  }

  func tearDown() {
    if let keyboardHideObserver {
      NotificationCenter.default.removeObserver(keyboardHideObserver)
      self.keyboardHideObserver = nil
    }
    onKeyboardDismissed = nil
    appInteractionShield?.removeFromSuperview()
    appInteractionShield = nil
    presentationView.removeFromSuperview()
    let completion = onEnded
    onEnded = nil
    completion?()
  }

  func updateFrame(_ frame: CGRect) {
    hostingController.view.frame = frame
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

  @objc private func handleAppOutsideTap() {
    notifyOutsideTap()
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
