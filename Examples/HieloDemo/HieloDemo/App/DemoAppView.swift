import SwiftUI

struct DemoAppView: View {
  var body: some View {
    NavigationStack {
      List {
        NavigationLink {
          MessagesDemoView()
        } label: {
          DemoRow(
            title: "Messages",
            subtitle: "Glass popover button",
            imageName: "AppIcon-Messages"
          )
        }
        NavigationLink {
          ChatGPTDemoView()
        } label: {
          DemoRow(
            title: "ChatGPT",
            subtitle: "Inline popover button",
            imageName: "AppIcon-ChatGPT"
          )
        }
      }
      .navigationTitle("Demos")
    }
  }
}

#Preview {
  DemoAppView()
}
