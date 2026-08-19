import SwiftUI
import UIKit
import XCTest

@testable import KeyboardFreeze

@MainActor
final class KeyboardFreezeTests: XCTestCase {
  func testMissingKeyboardFailsClosed() {
    let runtime = FakeKeyboardFreezeRuntime()
    let session = makeSession(runtime: runtime)
    var didResign = false

    let overlayResult = session.presentOverlay { _ in
      Text("Overlay")
    }
    let pinResult = session.pinKeyboard {
      didResign = true
    }

    XCTAssertEqual(overlayResult, .keyboardUnavailable)
    XCTAssertEqual(pinResult, .keyboardUnavailable)
    XCTAssertEqual(session.status, .idle)
    XCTAssertFalse(didResign)
  }

  func testMissingSourceFailsClosed() {
    let runtime = FakeKeyboardFreezeRuntime.populated()
    let session = makeSession(runtime: runtime)
    let source = KeyboardFreezeSource()

    let result = session.presentOverlay(from: source) { _ in
      Text("Overlay")
    }

    XCTAssertEqual(result, .sourceUnavailable)
    XCTAssertEqual(session.status, .idle)
  }

  func testOverlayStartsAndDefaultOutsideTapDismisses() {
    let runtime = FakeKeyboardFreezeRuntime.populated()
    let session = makeSession(runtime: runtime)

    let result = session.presentOverlay { _ in
      Text("Overlay")
    }

    XCTAssertEqual(result, .started)
    XCTAssertEqual(session.status, .overlay)
    XCTAssertEqual(runtime.pausedSnapshots.count, 1)

    session.handleOutsideOverlayTap()

    XCTAssertEqual(session.status, .idle)
  }

  func testCustomOutsideTapIsCalled() {
    let runtime = FakeKeyboardFreezeRuntime.populated()
    let session = makeSession(runtime: runtime)
    var outsideTapCount = 0

    _ = session.presentOverlay(
      onOutsideTap: {
        outsideTapCount += 1
      },
      content: { _ in
        Text("Overlay")
      }
    )

    session.handleOutsideOverlayTap()

    XCTAssertEqual(outsideTapCount, 1)
    XCTAssertEqual(session.status, .overlay)
    session.dismissOverlay()
  }

  func testOverlayBlocksPinning() {
    let runtime = FakeKeyboardFreezeRuntime.populated()
    let session = makeSession(runtime: runtime)
    _ = session.presentOverlay { _ in Text("Overlay") }

    let result = session.pinKeyboard {}

    XCTAssertEqual(result, .blockedByActivePresentation(.overlay))
    XCTAssertEqual(session.status, .overlay)
  }

  func testPinMountsSnapshotBeforeResigningFocus() async {
    let runtime = FakeKeyboardFreezeRuntime.populated()
    let session = makeSession(runtime: runtime)
    var didResign = false

    let result = session.pinKeyboard {
      didResign = true
    }

    XCTAssertEqual(result, .started)
    XCTAssertEqual(session.status, .pinned)
    XCTAssertFalse(didResign)

    for _ in 0..<10 where !didResign {
      await Task.yield()
    }

    XCTAssertTrue(didResign)
    XCTAssertEqual(runtime.pausedSnapshots.count, 1)
  }

  func testPinnedSnapshotDoesNotAddSafeAreaTwice() {
    let runtime = FakeKeyboardFreezeRuntime.populated(keyboardHeight: 280)
    let session = makeSession(runtime: runtime)
    _ = session.pinKeyboard {}
    let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 280))

    session.layoutPageSnapshot(in: container)

    guard let snapshot = runtime.captureResult?.snapshotView else {
      return XCTFail("Expected the fake runtime to provide a snapshot")
    }
    XCTAssertTrue(snapshot.superview === container)
    XCTAssertEqual(snapshot.frame.minY, 0, accuracy: 0.5)
    XCTAssertEqual(snapshot.frame.height, 280, accuracy: 0.5)
  }

  func testRestorationFinishesForItsNotification() async {
    let runtime = FakeKeyboardFreezeRuntime.populated()
    let notificationCenter = NotificationCenter()
    let session = makeSession(runtime: runtime, notificationCenter: notificationCenter)
    _ = session.pinKeyboard {}

    session.restoreKeyboard {}

    XCTAssertEqual(session.status, .restoring)
    XCTAssertEqual(runtime.captureResult?.keyboardWindow.alpha, 0)

    notificationCenter.post(
      name: UIResponder.keyboardDidShowNotification,
      object: nil
    )
    await Task.yield()

    XCTAssertEqual(session.status, .idle)
    XCTAssertEqual(runtime.captureResult?.keyboardWindow.alpha, 1)
  }

  func testRestorationCanBeInterruptedAndRepinned() async {
    let runtime = FakeKeyboardFreezeRuntime.populated()
    let notificationCenter = NotificationCenter()
    let session = makeSession(runtime: runtime, notificationCenter: notificationCenter)
    _ = session.pinKeyboard {}
    session.restoreKeyboard {}

    let result = session.pinKeyboard {}

    XCTAssertEqual(result, .started)
    XCTAssertEqual(session.status, .repinning)

    notificationCenter.post(
      name: UIResponder.keyboardDidHideNotification,
      object: nil
    )
    await Task.yield()

    XCTAssertEqual(session.status, .pinned)
    XCTAssertEqual(runtime.captureResult?.keyboardWindow.alpha, 1)
  }

  func testCancelIsIdempotentAndRestoresWindowAlpha() {
    let runtime = FakeKeyboardFreezeRuntime.populated()
    let session = makeSession(runtime: runtime)
    _ = session.pinKeyboard {}
    session.restoreKeyboard {}

    session.cancel()
    session.cancel()

    XCTAssertEqual(session.status, .idle)
    XCTAssertEqual(runtime.captureResult?.keyboardWindow.alpha, 1)
    XCTAssertNil(runtime.captureResult?.snapshotView.superview)
  }

  private func makeSession(
    runtime: FakeKeyboardFreezeRuntime,
    notificationCenter: NotificationCenter = NotificationCenter()
  ) -> KeyboardFreeze {
    KeyboardFreeze(
      configuration: .init(
        restorationTimeout: .seconds(5),
        repinningTimeout: .seconds(5)
      ),
      runtime: runtime,
      notificationCenter: notificationCenter
    )
  }
}
