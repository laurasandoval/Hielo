import SwiftUI
import UIKit

@MainActor
struct KeyboardPopoverPanGesture: UIGestureRecognizerRepresentable {
  let isEnabled: Bool
  let onChanged: @MainActor (CGSize) -> Void
  let onEnded: @MainActor (CGSize, CGSize) -> Void
  let onCancelled: @MainActor () -> Void

  func makeCoordinator(converter _: CoordinateSpaceConverter) -> Coordinator {
    Coordinator()
  }

  func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
    let recognizer = UIPanGestureRecognizer()
    recognizer.delegate = context.coordinator
    recognizer.maximumNumberOfTouches = 1
    return recognizer
  }

  func updateUIGestureRecognizer(
    _ recognizer: UIPanGestureRecognizer,
    context _: Context
  ) {
    recognizer.isEnabled = isEnabled
  }

  func handleUIGestureRecognizerAction(
    _ recognizer: UIPanGestureRecognizer,
    context: Context
  ) {
    let translation =
      context.converter.localTranslation.map {
        CGSize(width: $0.x, height: $0.y)
      } ?? .zero

    switch recognizer.state {
    case .began, .changed:
      onChanged(translation)
    case .ended:
      let velocity =
        context.converter.localVelocity.map {
          CGSize(width: $0.x, height: $0.y)
        } ?? .zero
      onEnded(
        translation,
        KeyboardPopoverDragBehavior.predictedEndTranslation(
          translation: translation,
          velocity: velocity
        )
      )
    case .cancelled:
      onCancelled()
    default:
      break
    }
  }

  final class Coordinator: NSObject, UIGestureRecognizerDelegate {
    private weak var touchedScrollView: UIScrollView?

    func gestureRecognizer(
      _: UIGestureRecognizer,
      shouldReceive touch: UITouch
    ) -> Bool {
      touchedScrollView = enclosingScrollView(for: touch.view)
      return true
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
      guard let recognizer = gestureRecognizer as? UIPanGestureRecognizer else {
        return true
      }
      guard let scrollView = touchedScrollView, scrollView.isScrollEnabled else {
        return true
      }

      let inset = scrollView.adjustedContentInset
      let canScrollHorizontally =
        scrollView.contentSize.width + inset.left + inset.right
        > scrollView.bounds.width + KeyboardPopoverMotion.scrollBoundaryTolerance
      let canScrollVertically =
        scrollView.contentSize.height + inset.top + inset.bottom
        > scrollView.bounds.height + KeyboardPopoverMotion.scrollBoundaryTolerance

      let velocity = recognizer.velocity(in: recognizer.view)
      return KeyboardPopoverDragBehavior.popoverShouldOwnGesture(
        velocity: CGSize(width: velocity.x, height: velocity.y),
        canScrollHorizontally: canScrollHorizontally,
        canScrollVertically: canScrollVertically,
        verticalDistanceFromTop: scrollView.contentOffset.y + inset.top
      )
    }

    func gestureRecognizer(
      _ gestureRecognizer: UIGestureRecognizer,
      shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
      guard gestureRecognizer is UIPanGestureRecognizer else { return false }
      return otherGestureRecognizer === touchedScrollView?.panGestureRecognizer
    }

    private func enclosingScrollView(for view: UIView?) -> UIScrollView? {
      var candidate = view
      while let view = candidate {
        if let scrollView = view as? UIScrollView {
          return scrollView
        }
        candidate = view.superview
      }
      return nil
    }
  }
}
