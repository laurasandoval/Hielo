import SwiftUI
import UIKit
import XCTest

@testable import Hielo

@MainActor
final class HieloPopoverPresentationTests: XCTestCase {
  func testPresentedPopoverStartsOverlayWhileKeyboardIsAvailable() async {
    let runtime = FakeHieloRuntime.populated()
    let session = HieloSession(
      configuration: .init(),
      runtime: runtime,
      notificationCenter: NotificationCenter()
    )
    let window = FakeHieloRuntime.makeWindow()
    window.frame = CGRect(x: 37, y: 53, width: 390, height: 700)
    let rootView = VStack {
      Spacer()
      Text("Source")
        .frame(width: 48, height: 48)
        .hieloPopover(
          isPresented: .constant(true),
          sourceGlass: nil
        ) {
          Text("Popover")
            .frame(width: 250, height: 250)
        }
    }
    .frame(width: 390, height: 700)
    .hieloHost(session, lifecycle: .manual)
    let hostingController = UIHostingController(rootView: rootView)

    defer {
      session.cancel()
      window.isHidden = true
      window.rootViewController = nil
    }

    window.rootViewController = hostingController
    window.makeKeyAndVisible()
    hostingController.view.layoutIfNeeded()

    for _ in 0..<30 where session.status == .idle {
      try? await Task.sleep(for: .milliseconds(10))
    }

    XCTAssertEqual(session.status, .overlay)
  }
}
