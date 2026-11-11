import SwiftUI
import UIKit
import XCTest

@testable import Hielo

@MainActor
final class HieloSessionOverlayTests: XCTestCase {
  func testAdaptiveOverlayUsesSourceWindowWithoutKeyboard() {
    let runtime = FakeHieloRuntime()
    let session = makeSession(runtime: runtime)
    let source = HieloSource()
    let window = FakeHieloRuntime.makeWindow()
    window.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
    let owner = UIView(frame: CGRect(x: 28, y: 760, width: 48, height: 48))
    window.addSubview(owner)
    source.update(
      frameInScreen: owner.convert(owner.bounds, to: nil),
      owner: owner
    )

    let result = session.presentAdaptiveOverlay(
      id: UUID(),
      onEnded: {},
      from: source,
      sourceFrame: owner.convert(owner.bounds, to: nil),
      overlayFrame: { _ in CGRect(x: 28, y: 558, width: 250, height: 250) },
      content: { _ in
        Text("Popover")
      }
    )

    XCTAssertEqual(result, .started)
    XCTAssertEqual(session.status, .overlay)
    XCTAssertTrue(runtime.pausedSnapshots.isEmpty)

    session.dismissOverlay()
    XCTAssertEqual(session.status, .idle)
  }

  func testAdaptiveOverlayUsesMeasuredFrameWithKeyboard() {
    let runtime = FakeHieloRuntime.populated()
    let session = makeSession(runtime: runtime)
    let sourceFrame = CGRect(x: 28, y: 760, width: 48, height: 48)

    let result = session.presentAdaptiveOverlay(
      id: UUID(),
      onEnded: {},
      from: HieloSource(),
      sourceFrame: sourceFrame,
      overlayFrame: { _ in CGRect(x: 28, y: 558, width: 250, height: 250) },
      content: { context in
        Text("\(context.sourceFrame.minX)")
      }
    )

    XCTAssertEqual(result, .started)
    XCTAssertEqual(session.status, .overlay)
    XCTAssertEqual(runtime.pausedSnapshots.count, 1)

    session.dismissOverlay()
  }

  private func makeSession(runtime: FakeHieloRuntime) -> HieloSession {
    HieloSession(runtime: runtime)
  }
}
