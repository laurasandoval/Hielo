import SwiftUI

struct DemoAppView: View {
  var body: some View {
    NavigationStack {
      List {
        Section {
          NavigationLink {
            MessagesDemoView()
          } label: {
            DemoRow(
              title: "Messages",
              subtitle: "Glass popover and photo picker",
              imageName: "AppIcon-Messages"
            )
          }
        } footer: {
          Text("Messages icons and artwork shown in this demo are the property of Apple.")
        }
      }
      .navigationTitle("Demos")
    }
  }
}

#Preview {
  DemoAppView()
}
