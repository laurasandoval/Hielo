import Hielo
import PhotosUI
import SwiftUI

struct MessagesDemoView: View {
  /// The sheet height to use before any docked keyboard has appeared, as a
  /// keyboard overlap that includes the bottom safe area.
  private static let fallbackKeyboardHeight: CGFloat = 336

  @State private var text = ""
  @State private var isMenuPresented = false
  @State private var isPhotoPickerPresented = false
  @State private var showsPhotoPickerAfterMenu = false
  @State private var photoSelection: PhotosPickerItem?
  @State private var keyboard = HieloKeyboardHeight()
  @State private var bottomSafeAreaInset: CGFloat = 0
  @FocusState private var inputIsFocused: Bool

  /// The keyboard's last overlap with the window bottom, including the bottom safe area.
  private var keyboardHeight: CGFloat {
    keyboard.lastVisible > 0 ? keyboard.lastVisible : Self.fallbackKeyboardHeight
  }

  /// Sheet detents are measured within the sheet's safe area, so the bottom
  /// inset is subtracted for the sheet's top to meet the keyboard's former top edge.
  private var photoPickerDetent: PresentationDetent {
    .height(keyboardHeight - bottomSafeAreaInset)
  }

  var body: some View {
    ZStack {
      Rectangle()
        .fill(.background)
        .ignoresSafeArea()

      ScrollView {
        Color.clear.frame(height: 1)
      }
      .contentShape(.rect)
      .onTapGesture { inputIsFocused = false }
      .scrollDismissesKeyboard(.interactively)

      VStack {
        Spacer()

        DemoComposer(text: $text, focus: $inputIsFocused) {
          DemoComposerButton {
            isMenuPresented = true
          }
          .hieloPopover(
            isPresented: $isMenuPresented,
            attachmentAnchor: .leading,
            onDismiss: showPhotoPickerIfRequested
          ) {
            MessagesDemoMenu(onSelectPhotos: requestPhotoPicker)
          }
          .hieloPopoverStyle(.glass)
        }
        .padding(inputIsFocused || isPhotoPickerPresented ? 15 : 27)
        // While the sheet replaces the keyboard, hold the composer where it
        // sat above the keyboard.
        .padding(.bottom, isPhotoPickerPresented ? keyboardHeight : 0)
        .animation(.smooth(duration: 0.2), value: inputIsFocused)
        .animation(.smooth(duration: 0.2), value: isPhotoPickerPresented)
      }
      .ignoresSafeArea(isPhotoPickerPresented ? .keyboard : [], edges: .bottom)
    }
    .ignoresSafeArea(.container, edges: .bottom)
    .background {
      // Read inside the keyboard-ignoring region so the inset excludes the keyboard.
      Color.clear
        .onGeometryChange(for: CGFloat.self) {
          $0.safeAreaInsets.bottom
        } action: {
          bottomSafeAreaInset = $0
        }
        .ignoresSafeArea(.keyboard)
    }
    .onHieloKeyboardHeightChange { keyboard = $0 }
    .onChange(of: inputIsFocused) { _, isFocused in
      // Tapping the text field trades the sheet for the keyboard.
      if isFocused { isPhotoPickerPresented = false }
    }
    .sheet(isPresented: $isPhotoPickerPresented) {
      MessagesDemoPhotoPicker(selection: $photoSelection)
        .presentationDetents([photoPickerDetent, .large])
        .presentationBackgroundInteraction(.enabled(upThrough: photoPickerDetent))
    }
    .navigationTitle("Messages")
    .navigationBarTitleDisplayMode(.inline)
    .hieloHost()
  }

  /// Collapses the popover first; the picker follows once it has dismissed.
  private func requestPhotoPicker() {
    showsPhotoPickerAfterMenu = true
    isMenuPresented = false
  }

  /// Trades the keyboard for the photo picker after the popover has morphed
  /// back into its source. A sheet can't appear above the live keyboard, so
  /// focus drops as the sheet rises into the keyboard's place.
  private func showPhotoPickerIfRequested() {
    guard showsPhotoPickerAfterMenu else { return }
    showsPhotoPickerAfterMenu = false
    inputIsFocused = false
    isPhotoPickerPresented = true
  }
}

#Preview {
  NavigationStack { MessagesDemoView() }
}
