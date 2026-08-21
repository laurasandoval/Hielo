import XCTest

@testable import KeyboardFreeze

final class KeyboardPopoverPresentationReadinessTests: XCTestCase {
  func testAllowsDivergentResolvedAndMeasuredSourceFrames() {
    let canPresent = KeyboardPopoverPresentationReadiness.canPresent(
      isPresented: true,
      isHosted: false,
      resolvedSourceFrame: CGRect(x: 28, y: 460, width: 48, height: 48),
      measuredSourceFrame: CGRect(x: 28, y: 760, width: 48, height: 48),
      destinationSize: CGSize(width: 250, height: 250)
    )

    XCTAssertTrue(canPresent)
  }

  func testAllowsAnUnresolvedSourceForKeyboardBackedPresentation() {
    XCTAssertTrue(
      KeyboardPopoverPresentationReadiness.canPresent(
        isPresented: true,
        isHosted: false,
        resolvedSourceFrame: nil,
        measuredSourceFrame: CGRect(x: 28, y: 760, width: 48, height: 48),
        destinationSize: CGSize(width: 250, height: 250)
      )
    )
  }

  func testRequiresUsableMeasurements() {
    XCTAssertFalse(
      KeyboardPopoverPresentationReadiness.canPresent(
        isPresented: true,
        isHosted: false,
        resolvedSourceFrame: CGRect(x: 28, y: 460, width: 48, height: 48),
        measuredSourceFrame: .zero,
        destinationSize: CGSize(width: 250, height: 250)
      )
    )
    XCTAssertFalse(
      KeyboardPopoverPresentationReadiness.canPresent(
        isPresented: true,
        isHosted: false,
        resolvedSourceFrame: CGRect(x: 28, y: 460, width: 48, height: 48),
        measuredSourceFrame: CGRect(x: 28, y: 760, width: 48, height: 48),
        destinationSize: .zero
      )
    )
  }

  func testRequiresRequestedPresentationThatIsNotAlreadyHosted() {
    let sourceFrame = CGRect(x: 28, y: 760, width: 48, height: 48)
    let destinationSize = CGSize(width: 250, height: 250)

    XCTAssertFalse(
      KeyboardPopoverPresentationReadiness.canPresent(
        isPresented: false,
        isHosted: false,
        resolvedSourceFrame: sourceFrame,
        measuredSourceFrame: sourceFrame,
        destinationSize: destinationSize
      )
    )
    XCTAssertFalse(
      KeyboardPopoverPresentationReadiness.canPresent(
        isPresented: true,
        isHosted: true,
        resolvedSourceFrame: sourceFrame,
        measuredSourceFrame: sourceFrame,
        destinationSize: destinationSize
      )
    )
  }
}
