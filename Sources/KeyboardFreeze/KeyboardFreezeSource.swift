import Observation
import SwiftUI
import UIKit

/// Tracks a SwiftUI view that overlay content can animate from or position around.
@MainActor
@Observable
public final class KeyboardFreezeSource {
  public private(set) var frameInScreen: CGRect?

  @ObservationIgnored private var screen: UIScreen?
  @ObservationIgnored private weak var owner: UIView?

  public init() {}

  func resolveFrame(on expectedScreen: UIScreen) -> CGRect? {
    guard screen === expectedScreen else { return nil }
    return frameInScreen
  }

  func update(frameInScreen: CGRect, screen: UIScreen, owner: UIView) {
    guard !frameInScreen.isEmpty else { return }
    self.owner = owner
    self.screen = screen
    self.frameInScreen = frameInScreen
  }

  func clear(owner: UIView) {
    guard self.owner === owner else { return }
    self.owner = nil
    screen = nil
    frameInScreen = nil
  }
}

extension View {
  /// Marks this view as an overlay source without requiring manual coordinates.
  public func keyboardFreezeSource(_ source: KeyboardFreezeSource) -> some View {
    background(KeyboardFreezeSourceReader(source: source))
  }
}

private struct KeyboardFreezeSourceReader: UIViewRepresentable {
  let source: KeyboardFreezeSource

  func makeUIView(context: Context) -> KeyboardFreezeSourceHostView {
    KeyboardFreezeSourceHostView(source: source)
  }

  func updateUIView(_ uiView: KeyboardFreezeSourceHostView, context: Context) {
    uiView.source = source
    uiView.setNeedsLayout()
  }
}

@MainActor
private final class KeyboardFreezeSourceHostView: UIView {
  var source: KeyboardFreezeSource {
    didSet {
      guard oldValue !== source else { return }
      oldValue.clear(owner: self)
      updateSource()
    }
  }

  init(source: KeyboardFreezeSource) {
    self.source = source
    super.init(frame: .zero)
    backgroundColor = .clear
    isUserInteractionEnabled = false
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) is unavailable")
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    if window == nil {
      source.clear(owner: self)
    } else {
      updateSource()
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    updateSource()
  }

  private func updateSource() {
    guard let screen = window?.screen else { return }
    source.update(
      frameInScreen: convert(bounds, to: nil),
      screen: screen,
      owner: self
    )
  }
}
