import CoreGraphics
import XCTest

@testable import Hielo

final class HieloPopoverDragBehaviorTests: XCTestCase {
  func testScrollableChildOwnsVerticalScrolling() {
    XCTAssertFalse(
      HieloPopoverDragBehavior.popoverShouldOwnGesture(
        velocity: CGSize(width: 0, height: -100),
        canScrollHorizontally: false,
        canScrollVertically: true,
        verticalDistanceFromTop: 0
      )
    )
    XCTAssertFalse(
      HieloPopoverDragBehavior.popoverShouldOwnGesture(
        velocity: CGSize(width: 0, height: 100),
        canScrollHorizontally: false,
        canScrollVertically: true,
        verticalDistanceFromTop: 20
      )
    )
  }

  func testPopoverOwnsDownwardDragAtTopOfScrollableChild() {
    XCTAssertTrue(
      HieloPopoverDragBehavior.popoverShouldOwnGesture(
        velocity: CGSize(width: 0, height: 100),
        canScrollHorizontally: false,
        canScrollVertically: true,
        verticalDistanceFromTop: 0
      )
    )
  }

  func testScrollableChildOnlyOwnsItsScrollableAxis() {
    XCTAssertTrue(
      HieloPopoverDragBehavior.popoverShouldOwnGesture(
        velocity: CGSize(width: 100, height: 10),
        canScrollHorizontally: false,
        canScrollVertically: true,
        verticalDistanceFromTop: 20
      )
    )
    XCTAssertFalse(
      HieloPopoverDragBehavior.popoverShouldOwnGesture(
        velocity: CGSize(width: 100, height: 10),
        canScrollHorizontally: true,
        canScrollVertically: false,
        verticalDistanceFromTop: 0
      )
    )
  }

  func testPopoverOwnsDragWhenChildDoesNotActuallyScroll() {
    XCTAssertTrue(
      HieloPopoverDragBehavior.popoverShouldOwnGesture(
        velocity: CGSize(width: 0, height: -100),
        canScrollHorizontally: false,
        canScrollVertically: false,
        verticalDistanceFromTop: 0
      )
    )
  }

  func testDragPredictionUsesCurrentVelocity() {
    XCTAssertEqual(
      HieloPopoverDragBehavior.predictedEndTranslation(
        translation: CGSize(width: 10, height: 20),
        velocity: CGSize(width: 100, height: 200)
      ),
      CGSize(width: 30, height: 60)
    )
  }

  func testRubberBandAllowsEveryDirectionButLimitsTravel() {
    let offset = HieloPopoverDragBehavior.rubberBandedOffset(
      for: CGSize(width: -500, height: -500)
    )

    XCTAssertLessThan(offset.width, 0)
    XCTAssertLessThan(offset.height, 0)
    XCTAssertGreaterThan(offset.width, -HieloPopoverMotion.horizontalDragLimit)
    XCTAssertGreaterThan(offset.height, -HieloPopoverMotion.upwardDragLimit)
  }

  func testOnlyDownwardMotionDismisses() {
    XCTAssertTrue(
      HieloPopoverDragBehavior.shouldDismiss(
        translation: CGSize(width: 0, height: 70),
        predictedEndTranslation: CGSize(width: 0, height: 90)
      )
    )
    XCTAssertTrue(
      HieloPopoverDragBehavior.shouldDismiss(
        translation: CGSize(width: 0, height: 20),
        predictedEndTranslation: CGSize(width: 0, height: 140)
      )
    )
    XCTAssertFalse(
      HieloPopoverDragBehavior.shouldDismiss(
        translation: CGSize(width: 300, height: -20),
        predictedEndTranslation: CGSize(width: 500, height: -80)
      )
    )
  }

  func testVerticalDragCommunicatesDismissalDirectionWithScale() {
    let upwardScale = HieloPopoverDragBehavior.scale(
      for: CGSize(width: 0, height: -20)
    )
    let downwardScale = HieloPopoverDragBehavior.scale(
      for: CGSize(width: 0, height: 40)
    )

    XCTAssertGreaterThan(upwardScale, 1)
    XCTAssertLessThan(downwardScale, 1)
  }
}
