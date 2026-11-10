import PhotosUI
import SwiftUI

/// An inline Photos picker shown in the space the keyboard occupied.
///
/// The picker runs out of process, so the app sees only what the person
/// selects and needs no photo library permission or usage description.
struct MessagesDemoPhotoPicker: View {
  @Binding var selection: PhotosPickerItem?

  var body: some View {
    PhotosPicker("Photos", selection: $selection)
      .photosPickerStyle(.inline)
      .photosPickerAccessoryVisibility(.hidden)
      .photosPickerDisabledCapabilities(.selectionActions)
  }
}
