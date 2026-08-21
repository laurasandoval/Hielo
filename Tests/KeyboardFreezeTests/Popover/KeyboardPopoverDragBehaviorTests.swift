import CoreGraphics
import XCTest

@testable import KeyboardFreeze

final class KeyboardPopoverDragBehaviorTests: XCTestCase {
  func testScrollableChildOwnsVerticalScrolling() {
    XCTAssertFalse(
      KeyboardPopoverDragBehavior.popoverShouldOwnGesture(
        velocity: CGSize(width: 0, height: -100),
        canScrollHorizontally: false,
        canScrollVertically: true,
        verticalDistanceFromTop: 0
      )
    )
    XCTAssertFalse(
      KeyboardPopoverDragBehavior.popoverShouldOwnGesture(
        velocity: CGSize(width: 0, height: 100),
        canScrollHorizontally: false,
        canScrollVertically: true,
        verticalDistanceFromTop: 20
      )
    )
  }

  func testPopoverOwnsDownwardDragAtTopOfScrollableChild() {
    XCTAssertTrue(
      KeyboardPopoverDragBehavior.popoverShouldOwnGesture(
        velocity: CGSize(width: 0, height: 100),
        canScrollHorizontally: false,
        canScrollVertically: true,
        verticalDistanceFromTop: 0
      )
    )
  }

  func testScrollableChildOnlyOwnsItsScrollableAxis() {
    XCTAssertTrue(
      KeyboardPopoverDragBehavior.popoverShouldOwnGesture(
        velocity: CGSize(width: 100, height: 10),
        canScrollHorizontally: false,
        canScrollVertically: true,
        verticalDistanceFromTop: 20
      )
    )
    XCTAssertFalse(
      KeyboardPopoverDragBehavior.popoverShouldOwnGesture(
        velocity: CGSize(width: 100, height: 10),
        canScrollHorizontally: true,
        canScrollVertically: false,
        verticalDistanceFromTop: 0
      )
    )
  }

  func testPopoverOwnsDragWhenChildDoesNotActuallyScroll() {
    XCTAssertTrue(
      KeyboardPopoverDragBehavior.popoverShouldOwnGesture(
        velocity: CGSize(width: 0, height: -100),
        canScrollHorizontally: false,
        canScrollVertically: false,
        verticalDistanceFromTop: 0
      )
    )
  }

  func testDragPredictionUsesCurrentVelocity() {
    XCTAssertEqual(
      KeyboardPopoverDragBehavior.predictedEndTranslation(
        translation: CGSize(width: 10, height: 20),
        velocity: CGSize(width: 100, height: 200)
      ),
      CGSize(width: 30, height: 60)
    )
  }

  func testRubberBandAllowsEveryDirectionButLimitsTravel() {
    let offset = KeyboardPopoverDragBehavior.rubberBandedOffset(
      for: CGSize(width: -500, height: -500)
    )

    XCTAssertLessThan(offset.width, 0)
    XCTAssertLessThan(offset.height, 0)
    XCTAssertGreaterThan(offset.width, -KeyboardPopoverMotion.horizontalDragLimit)
    XCTAssertGreaterThan(offset.height, -KeyboardPopoverMotion.upwardDragLimit)
  }

  func testOnlyDownwardMotionDismisses() {
    XCTAssertTrue(
      KeyboardPopoverDragBehavior.shouldDismiss(
        translation: CGSize(width: 0, height: 70),
        predictedEndTranslation: CGSize(width: 0, height: 90)
      )
    )
    XCTAssertTrue(
      KeyboardPopoverDragBehavior.shouldDismiss(
        translation: CGSize(width: 0, height: 20),
        predictedEndTranslation: CGSize(width: 0, height: 140)
      )
    )
    XCTAssertFalse(
      KeyboardPopoverDragBehavior.shouldDismiss(
        translation: CGSize(width: 300, height: -20),
        predictedEndTranslation: CGSize(width: 500, height: -80)
      )
    )
  }

  func testVerticalDragCommunicatesDismissalDirectionWithScale() {
    let upwardScale = KeyboardPopoverDragBehavior.scale(
      for: CGSize(width: 0, height: -20)
    )
    let downwardScale = KeyboardPopoverDragBehavior.scale(
      for: CGSize(width: 0, height: 40)
    )

    XCTAssertGreaterThan(upwardScale, 1)
    XCTAssertLessThan(downwardScale, 1)
  }
}
