import SwiftUI

struct AttachmentOverlay: View {
  let dismiss: () -> Void

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "snowflake")
        .font(.largeTitle)
        .foregroundStyle(.blue)
        .accessibilityHidden(true)

      Text("Keyboard frozen")
        .font(.headline)

      Text("Hello from above the keyboard.")
        .multilineTextAlignment(.center)
        .foregroundStyle(.secondary)

      Button("Done", action: dismiss)
        .buttonStyle(.glassProminent)
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .glassEffect(.regular, in: .rect(cornerRadius: 32))
  }
}

#Preview {
  AttachmentOverlay {}
    .frame(width: 250, height: 250)
    .padding()
}
