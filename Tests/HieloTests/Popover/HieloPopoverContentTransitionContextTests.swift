import SwiftUI
import XCTest

@testable import Hielo

final class HieloPopoverContentTransitionContextTests: XCTestCase {
  func testLiveSurfaceGeometryScalesBothContentSizes() {
    let menuSize = CGSize(width: 300, height: 450)
    let detailSize = CGSize(width: 375, height: 600)
    let context = HieloPopoverContentTransitionContext(
      surfaceSize: detailSize,
      isEnabled: true
    )

    XCTAssertEqual(context.scale(for: menuSize), 1.25)
    XCTAssertEqual(context.scale(for: detailSize), 1)
  }

  func testInitialSurfaceGeometryIsTheReverseOfFinalGeometry() {
    let menuSize = CGSize(width: 300, height: 450)
    let detailSize = CGSize(width: 375, height: 600)
    let context = HieloPopoverContentTransitionContext(
      surfaceSize: menuSize,
      isEnabled: true
    )

    XCTAssertEqual(context.scale(for: menuSize), 1)
    XCTAssertEqual(context.scale(for: detailSize), 0.8)
  }

  func testDisabledContextLeavesContentUntouched() {
    let context = HieloPopoverContentTransitionContext(
      surfaceSize: CGSize(width: 375, height: 600),
      isEnabled: false
    )

    XCTAssertEqual(context.scale(for: CGSize(width: 300, height: 450)), 1)
  }

  func testExpansionProgressFollowsSurfaceWidth() {
    let context = HieloPopoverContentTransitionContext(
      surfaceSize: CGSize(width: 337.5, height: 525),
      isEnabled: true
    )

    XCTAssertEqual(
      context.expansionProgress(
        collapsedSize: CGSize(width: 300, height: 450),
        expandedSize: CGSize(width: 375, height: 600)
      ),
      0.5
    )
  }

  func testExpansionProgressFallsBackToHeight() {
    let context = HieloPopoverContentTransitionContext(
      surfaceSize: CGSize(width: 300, height: 525),
      isEnabled: true
    )

    XCTAssertEqual(
      context.expansionProgress(
        collapsedSize: CGSize(width: 300, height: 450),
        expandedSize: CGSize(width: 300, height: 600)
      ),
      0.5
    )
  }

  func testDisabledContextDoesNotDriveExpansionProgress() {
    let context = HieloPopoverContentTransitionContext(
      surfaceSize: CGSize(width: 375, height: 600),
      isEnabled: false
    )

    XCTAssertNil(
      context.expansionProgress(
        collapsedSize: CGSize(width: 300, height: 450),
        expandedSize: CGSize(width: 375, height: 600)
      )
    )
  }

  func testCollapsedContentFadesOneToOneWithExpansionProgress() {
    let context = HieloPopoverContentTransitionContext(
      surfaceSize: CGSize(width: 356.25, height: 562.5),
      isEnabled: true
    )

    XCTAssertEqual(
      context.collapsedContentOpacity(
        collapsedSize: CGSize(width: 300, height: 450),
        expandedSize: CGSize(width: 375, height: 600)
      ),
      0.25
    )
  }

  func testCollapsedContentFadeUsesLiveExpansionProgress() {
    let context = HieloPopoverContentTransitionContext(
      surfaceSize: CGSize(width: 337.5, height: 525),
      isEnabled: true
    )

    XCTAssertEqual(
      context.collapsedContentOpacity(
        collapsedSize: CGSize(width: 300, height: 450),
        expandedSize: CGSize(width: 375, height: 600)
      ),
      0.5,
      accuracy: 0.000_001
    )
  }

  func testCollapsedContentStaysVisibleUntilLiveGeometryIsAvailable() {
    let context = HieloPopoverContentTransitionContext(
      surfaceSize: .zero,
      isEnabled: false
    )

    XCTAssertEqual(
      context.collapsedContentOpacity(
        collapsedSize: CGSize(width: 300, height: 450),
        expandedSize: CGSize(width: 375, height: 600)
      ),
      1
    )
  }

  func testExpandedContentFadesOneToOneWithExpansionProgress() {
    let context = HieloPopoverContentTransitionContext(
      surfaceSize: CGSize(width: 356.25, height: 562.5),
      isEnabled: true
    )

    XCTAssertEqual(
      context.expandedContentOpacity(
        collapsedSize: CGSize(width: 300, height: 450),
        expandedSize: CGSize(width: 375, height: 600)
      ),
      0.75
    )
  }

  func testExpandedContentUsesLiveExpansionProgress() {
    let context = HieloPopoverContentTransitionContext(
      surfaceSize: CGSize(width: 365.625, height: 581.25),
      isEnabled: true
    )

    XCTAssertEqual(
      context.expandedContentOpacity(
        collapsedSize: CGSize(width: 300, height: 450),
        expandedSize: CGSize(width: 375, height: 600)
      ),
      0.875,
      accuracy: 0.000_001
    )
  }

  func testExpandedContentIsFullyVisibleAtEndpoint() {
    let context = HieloPopoverContentTransitionContext(
      surfaceSize: CGSize(width: 375, height: 600),
      isEnabled: true
    )

    XCTAssertEqual(
      context.expandedContentOpacity(
        collapsedSize: CGSize(width: 300, height: 450),
        expandedSize: CGSize(width: 375, height: 600)
      ),
      1
    )
  }
}
