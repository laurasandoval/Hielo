import SwiftUI

/// A view that transitions between collapsed and expanded popover content.
///
/// Place this view inside a `hieloPopover` content closure. Changing
/// `isExpanded` updates the popover’s size while coordinating content scaling
/// and fading. Give each content view the layout it needs in its own state.
///
/// ```swift
/// HieloPopoverContentTransition(isExpanded: isExpanded) {
///     Text("Menu")
///         .frame(width: 300, height: 450)
/// } expanded: {
///     Text("Details")
///         .frame(width: 350, height: 550)
/// }
/// ```
///
/// Both content views participate in layout. Only the active content accepts
/// interaction and is exposed to accessibility.
public struct HieloPopoverContentTransition<CollapsedContent: View, ExpandedContent: View>:
  View
{
  private let isExpanded: Bool
  private let collapsedContent: CollapsedContent
  private let expandedContent: ExpandedContent

  @State private var collapsedSize = CGSize.zero
  @State private var expandedSize = CGSize.zero

  /// Creates a transition between two popover content views.
  ///
  /// - Parameters:
  ///   - isExpanded: Whether the expanded content is active.
  ///   - collapsed: A closure creating the collapsed content.
  ///   - expanded: A closure creating the expanded content.
  public init(
    isExpanded: Bool,
    @ViewBuilder collapsed: () -> CollapsedContent,
    @ViewBuilder expanded: () -> ExpandedContent
  ) {
    self.isExpanded = isExpanded
    collapsedContent = collapsed()
    expandedContent = expanded()
  }

  /// The content and layout of the transition.
  public var body: some View {
    HieloPopoverContentTransitionLayout(isExpanded: isExpanded) {
      HieloPopoverContentTransitionLayer(
        role: .collapsed,
        isExpanded: isExpanded,
        collapsedSize: collapsedSize,
        expandedSize: expandedSize,
        measuredSize: $collapsedSize,
        content: collapsedContent
      )

      HieloPopoverContentTransitionLayer(
        role: .expanded,
        isExpanded: isExpanded,
        collapsedSize: collapsedSize,
        expandedSize: expandedSize,
        measuredSize: $expandedSize,
        content: expandedContent
      )
    }
    .preference(
      key: HieloPopoverContentTransitionPreferenceKey.self,
      value: true
    )
  }
}
