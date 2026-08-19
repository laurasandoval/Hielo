import SwiftUI

struct ConversationView: View {
  var body: some View {
    ScrollView {
      LazyVStack(spacing: 14) {
        Text("This keyboard is about to get very still.")
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
          .background(.quaternary, in: .rect(cornerRadius: 20))
          .frame(maxWidth: .infinity, alignment: .leading)

        Text("Tap the message field, then press +")
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
          .foregroundStyle(.white)
          .background(.blue, in: .rect(cornerRadius: 20))
          .frame(maxWidth: .infinity, alignment: .trailing)
      }
      .padding(20)
    }
    .scrollDismissesKeyboard(.never)
  }
}

#Preview {
  ConversationView()
}
