import SwiftUI
import XCTest

@testable import Hielo

final class HieloPopoverShapeTransitionTests: XCTestCase {
  func testStandardShapesInterpolateBetweenFlexibleSizes() {
    let transition = HieloPopoverShapeTransition.standard

    XCTAssertEqual(
      transition.resolve(
        sourceSize: CGSize(width: 48, height: 48),
        destinationSize: CGSize(width: 250, height: 250),
        expansionProgress: 0
      ),
      RectangleCornerRadii(
        topLeading: 24,
        bottomLeading: 24,
        bottomTrailing: 24,
        topTrailing: 24
      )
    )
    XCTAssertEqual(
      transition.resolve(
        sourceSize: CGSize(width: 48, height: 48),
        destinationSize: CGSize(width: 250, height: 250),
        expansionProgress: 0.5
      ),
      RectangleCornerRadii(
        topLeading: 28,
        bottomLeading: 28,
        bottomTrailing: 28,
        topTrailing: 28
      )
    )
    XCTAssertEqual(
      transition.resolve(
        sourceSize: CGSize(width: 48, height: 48),
        destinationSize: CGSize(width: 250, height: 250),
        expansionProgress: 1
      ),
      RectangleCornerRadii(
        topLeading: 32,
        bottomLeading: 32,
        bottomTrailing: 32,
        topTrailing: 32
      )
    )
  }

  func testCustomShapesInterpolateEveryCorner() {
    let transition = HieloPopoverShapeTransition(
      sourceShape: .rect(cornerRadius: 8),
      popoverShape: .rect(
        cornerRadii: RectangleCornerRadii(
          topLeading: 32,
          bottomLeading: 24,
          bottomTrailing: 16,
          topTrailing: 8
        )
      )
    )

    XCTAssertEqual(
      transition.resolve(
        sourceSize: CGSize(width: 48, height: 48),
        destinationSize: CGSize(width: 250, height: 250),
        expansionProgress: 0.5
      ),
      RectangleCornerRadii(
        topLeading: 20,
        bottomLeading: 16,
        bottomTrailing: 12,
        topTrailing: 8
      )
    )
  }
}
