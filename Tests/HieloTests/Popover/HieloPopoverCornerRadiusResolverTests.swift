import UIKit
import XCTest

@testable import Hielo

@MainActor
final class HieloPopoverCornerRadiusResolverTests: XCTestCase {
  func testFixedRadiusDoesNotNeedAWindow() {
    let resolver = HieloPopoverCornerRadiusResolver()

    XCTAssertEqual(
      resolver.resolve(.fixed(24), for: CGRect(x: 0, y: 0, width: 200, height: 200)),
      24
    )
  }

  func testContainerConcentricRadiusUsesItsDestinationFrame() {
    let container = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
    let resolver = HieloPopoverCornerRadiusResolver()
    resolver.connect(to: container)
    container.cornerConfiguration = .uniformCorners(
      radius: .fixed(60)
    )

    let radius = resolver.resolve(
      .containerConcentric,
      for: container.bounds.insetBy(dx: 8, dy: 8)
    )

    XCTAssertEqual(radius, 54)
  }
}
