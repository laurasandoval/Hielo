import XCTest

@testable import KeyboardFreeze

@MainActor
final class KeyboardFreezeRuntimeTests: XCTestCase {
  func testPrivateSymbolAssembly() {
    XCTAssertEqual(
      KeyboardFreezeRuntime.remoteKeyboardWindowClassName,
      "UIRemoteKeyboardWindow"
    )
    XCTAssertEqual(
      KeyboardFreezeRuntime.remoteKeyboardWindowSelectorName,
      "remoteKeyboardWindowForScreen:create:"
    )
    XCTAssertEqual(
      KeyboardFreezeRuntime.inputSetHostViewClassName,
      "UIInputSetHostView"
    )
    XCTAssertEqual(
      KeyboardFreezeRuntime.snapshotterClassName,
      "UIKBViewTreeSnapshotter"
    )
    XCTAssertEqual(
      KeyboardFreezeRuntime.snapshotterFactorySelectorName,
      "snapshotterForKeyboardView:afterScreenUpdates:"
    )
    XCTAssertEqual(
      KeyboardFreezeRuntime.snapshotViewSelectorName,
      "snapshotView"
    )
  }

  func testActivationResultSuccess() {
    XCTAssertTrue(KeyboardFreezeActivationResult.started.succeeded)
    XCTAssertTrue(KeyboardFreezeActivationResult.alreadyActive.succeeded)
    XCTAssertFalse(KeyboardFreezeActivationResult.keyboardUnavailable.succeeded)
    XCTAssertFalse(KeyboardFreezeActivationResult.sourceUnavailable.succeeded)
  }
}
