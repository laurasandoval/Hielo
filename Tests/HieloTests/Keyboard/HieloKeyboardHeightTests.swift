import XCTest

@testable import Hielo

final class HieloKeyboardHeightTests: XCTestCase {
  func testDockedKeyboardReportsItsFullOverlap() {
    var height = HieloKeyboardHeight()

    height.update(overlap: 336, bottomSafeAreaInset: 34)

    XCTAssertEqual(height, HieloKeyboardHeight(current: 336, lastVisible: 336))
  }

  func testGuideRestingOnTheSafeAreaReportsNoKeyboard() {
    var height = HieloKeyboardHeight()

    height.update(overlap: 34, bottomSafeAreaInset: 34)

    XCTAssertEqual(height, HieloKeyboardHeight())
  }

  func testDismissalKeepsTheLastVisibleHeight() {
    var height = HieloKeyboardHeight()

    height.update(overlap: 336, bottomSafeAreaInset: 34)
    height.update(overlap: 34, bottomSafeAreaInset: 34)

    XCTAssertEqual(height, HieloKeyboardHeight(current: 0, lastVisible: 336))
  }

  func testLastVisibleFollowsANewKeyboardHeight() {
    var height = HieloKeyboardHeight(current: 0, lastVisible: 336)

    height.update(overlap: 291, bottomSafeAreaInset: 0)

    XCTAssertEqual(height, HieloKeyboardHeight(current: 291, lastVisible: 291))
  }
}
