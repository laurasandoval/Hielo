import SwiftUI

struct HieloPopoverContentTransitionLayer<Content: View>: View {
  let role: HieloPopoverContentTransitionRole
  let isExpanded: Bool
  let collapsedSize: CGSize
  let expandedSize: CGSize
  @Binding var measuredSize: CGSize
  let content: Content

  @Environment(\.hieloPopoverContentTransitionContext) private var context

  var body: some View {
    let context = context

    content
      .fixedSize()
      .modifier(
        HieloPopoverTransitionSurfaceModifier(
          isEnabled: context.rendersSurfaceGlass,
          cornerRadius: context.surfaceCornerRadius
        )
      )
      .modifier(
        HieloPopoverContentOpacityModifier(
          progress: expansionProgress,
          role: role
        )
      )
      .visualEffect { content, proxy in
        content.scaleEffect(
          context.scale(for: proxy.size),
          anchor: .center
        )
      }
      .zIndex(zIndex)
      .allowsHitTesting(allowsHitTesting)
      .accessibilityHidden(!allowsHitTesting)
      .onGeometryChange(for: CGSize.self) { proxy in
        proxy.size
      } action: { size in
        guard size.width > 0, size.height > 0 else { return }
        measuredSize = size
      }
  }

  private var expansionProgress: Double {
    context.expansionProgress(
      collapsedSize: collapsedSize,
      expandedSize: expandedSize
    ) ?? 0
  }

  private var allowsHitTesting: Bool {
    switch role {
    case .collapsed:
      return !isExpanded
    case .expanded:
      return isExpanded
    }
  }

  private var zIndex: Double {
    switch (role, isExpanded) {
    case (.collapsed, true), (.expanded, false):
      return 1
    default:
      return 0
    }
  }
}
