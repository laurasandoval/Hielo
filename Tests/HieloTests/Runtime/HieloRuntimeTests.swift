import XCTest

@testable import Hielo

@MainActor
final class HieloRuntimeTests: XCTestCase {
  func testPrivateSymbolAssembly() {
    XCTAssertEqual(
      HieloRuntime.remoteKeyboardWindowClassName,
      "UIRemoteKeyboardWindow"
    )
    XCTAssertEqual(
      HieloRuntime.keyboardSceneDelegateSelectorName,
      "keyboardSceneDelegate"
    )
    XCTAssertEqual(
      HieloRuntime.inputSetHostViewClassName,
      "UIInputSetHostView"
    )
    XCTAssertEqual(
      HieloRuntime.snapshotterClassName,
      "UIKBViewTreeSnapshotter"
    )
    XCTAssertEqual(
      HieloRuntime.snapshotterFactorySelectorName,
      "snapshotterForKeyboardView:afterScreenUpdates:"
    )
    XCTAssertEqual(
      HieloRuntime.snapshotViewSelectorName,
      "snapshotView"
    )
  }

  func testActivationResultSuccess() {
    XCTAssertTrue(HieloActivationResult.started.succeeded)
    XCTAssertTrue(HieloActivationResult.alreadyActive.succeeded)
    XCTAssertFalse(HieloActivationResult.keyboardUnavailable.succeeded)
    XCTAssertFalse(HieloActivationResult.sourceUnavailable.succeeded)
  }
}
