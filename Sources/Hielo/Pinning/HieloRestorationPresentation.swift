import UIKit

@MainActor
final class HieloRestorationPresentation: NSObject {
  private struct HiddenWindow {
    let window: UIWindow
    let restoredAlpha: CGFloat
  }

  private let keyboardWindow: UIWindow
  private let runtime: any HieloRuntimeProviding
  private var hiddenWindows: [ObjectIdentifier: HiddenWindow] = [:]
  private var displayLink: CADisplayLink?
  private var isTornDown = false

  init(
    pin: HieloPin,
    runtime: any HieloRuntimeProviding
  ) {
    keyboardWindow = pin.keyboardWindow
    self.runtime = runtime
    super.init()

    hideKeyboardWindows()
    let displayLink = CADisplayLink(
      target: self,
      selector: #selector(handleDisplayLink)
    )
    displayLink.add(to: .main, forMode: .common)
    self.displayLink = displayLink
  }

  func hideKeyboardWindows() {
    let windows = [keyboardWindow] + runtime.keyboardWindows(on: keyboardWindow.screen)
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    for window in windows {
      let identifier = ObjectIdentifier(window)
      if hiddenWindows[identifier] == nil {
        hiddenWindows[identifier] = HiddenWindow(
          window: window,
          restoredAlpha: window.alpha > 0.01 ? window.alpha : 1
        )
      }
      window.alpha = 0
    }
    CATransaction.commit()
  }

  func tearDown() {
    guard !isTornDown else { return }
    isTornDown = true
    displayLink?.invalidate()
    displayLink = nil

    CATransaction.begin()
    CATransaction.setDisableActions(true)
    for hiddenWindow in hiddenWindows.values {
      hiddenWindow.window.layer.removeAnimation(forKey: "opacity")
      hiddenWindow.window.alpha = hiddenWindow.restoredAlpha
      hiddenWindow.window.layoutIfNeeded()
    }
    CATransaction.commit()
    hiddenWindows.removeAll()
  }

  @objc private func handleDisplayLink() {
    hideKeyboardWindows()
  }
}
