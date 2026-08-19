import SwiftUI

struct DemoListView: View {
  var body: some View {
    List {
      Section {
        NavigationLink {
          OverlayDemoView()
        } label: {
          Label("Content above keyboard", systemImage: "rectangle.bottomhalf.inset.filled")
        }

        NavigationLink {
          SidebarDemoView()
        } label: {
          Label("Moving sidebar", systemImage: "sidebar.left")
        }
      } footer: {
        Text("Use a software keyboard to see the frozen surface.")
      }
    }
    .navigationTitle("KeyboardFreeze")
  }
}

#Preview {
  NavigationStack {
    DemoListView()
  }
}
