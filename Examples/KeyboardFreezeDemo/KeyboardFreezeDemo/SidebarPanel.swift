import SwiftUI

struct SidebarPanel: View {
  let close: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      HStack {
        Text("Sidebar")
          .font(.title2)
          .bold()

        Spacer()

        Button("Close sidebar", systemImage: "xmark", action: close)
          .labelStyle(.iconOnly)
          .buttonStyle(.glass)
          .buttonBorderShape(.circle)
      }

      Label("New conversation", systemImage: "square.and.pencil")
      Label("Saved messages", systemImage: "bookmark")
      Label("Settings", systemImage: "gearshape")

      Spacer()
    }
    .padding(24)
    .frame(width: 300, alignment: .leading)
    .frame(maxHeight: .infinity)
    .background(.blue.opacity(0.12))
  }
}

#Preview {
  SidebarPanel {}
}
