import SwiftUI

struct KeyboardPopoverPresenter: View {
  @Binding var isPresented: Bool
  let sourceFrame: CGRect

  @Namespace private var menuTransition

  var body: some View {
    Button("Toggle menu", systemImage: "plus") {
      isPresented.toggle()
    }
    .labelStyle(.iconOnly)
    .font(.title3)
    .frame(width: 48, height: 48)
    .contentShape(.circle)
    .buttonStyle(.plain)
    .glassEffect(.regular.interactive(), in: .circle)
    .matchedTransitionSource(id: "keyboardMenu", in: menuTransition)
    .popover(
      isPresented: $isPresented,
      attachmentAnchor: .point(.leading),
      arrowEdge: .leading
    ) {
      KeyboardMenuContent(sourceFrame: sourceFrame)
        .navigationTransition(
          .zoom(sourceID: "keyboardMenu", in: menuTransition)
        )
    }
  }
}
