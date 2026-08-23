import Hielo
import SwiftUI

struct ChatGPTDemoMenu: View {
  @State private var selection: ChatGPTDemoMenuItem?
  @State private var displayedItem: ChatGPTDemoMenuItem?

  var body: some View {
    HieloPopoverContentTransition(isExpanded: selection != nil) {
      menu
    } expanded: {
      ChatGPTDemoExpandedView(item: displayedItem) {
        self.selection = nil
      }
    }
    .sensoryFeedback(.impact(weight: .light), trigger: selection)
    .hieloPopoverCornerRadius(
      selection == nil ? .fixed(45) : .containerConcentric
    )
    .hieloPopoverDragDismissDisabled(selection != nil)
    .hieloPopoverPlacement(
      selection == nil ? .source : .container(.bottom, inset: 8)
    )
  }

  private var menu: some View {
    ScrollView {
      VStack(spacing: 0) {
        ForEach(ChatGPTDemoMenuItem.allCases) { item in
          Button {
            select(item)
          } label: {
            ChatGPTDemoMenuRow(title: item.title, systemImage: item.systemImage)
              .contentShape(.rect)
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.vertical, 12)
    }
    .frame(width: 300, height: 228)
    .scrollIndicators(.hidden)
  }

  private func select(_ item: ChatGPTDemoMenuItem) {
    displayedItem = item
    selection = item
  }
}
