import SwiftUI

struct DemoAppView: View {
  var body: some View {
    NavigationStack {
      List {
        NavigationLink {
          MessagesDemoView()
        } label: {
          Label("Messages — glass button", systemImage: "message")
        }
        NavigationLink {
          ChatGPTDemoView()
        } label: {
          Label("ChatGPT — inline button", systemImage: "bubble.left.and.bubble.right")
        }
      }
      .navigationTitle("HieloSession Demos")
    }
  }
}

#Preview {
  DemoAppView()
}
