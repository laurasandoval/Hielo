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
  @State private var photoPickerAwaitsKeyboardHide = false
  @State private var composerHold: CGFloat = 0
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

  /// The composer's distance from the window bottom: the system's keyboard
  /// inset, or the height held for the photo picker, whichever is larger. One
  /// value drives both states, so trading the keyboard for the sheet (and
  /// back) never moves the composer.
  private func composerBottomInset(systemInset: CGFloat) -> CGFloat {
    let inset = max(systemInset, composerHold)
    return inset > bottomSafeAreaInset ? inset : 0
  }

  var body: some View {
    // Read above the safe-area-ignoring content so the inset includes the keyboard.
    GeometryReader { proxy in
      let bottomInset = composerBottomInset(systemInset: proxy.safeAreaInsets.bottom)

      ZStack {
        Rectangle()
          .fill(.background)

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
          }
          .padding(bottomInset > 0 ? 15 : 27)
          .padding(.bottom, bottomInset)
        }
      }
      .ignoresSafeArea(.all, edges: .bottom)
    }
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
    .onHieloKeyboardHeightChange {
      keyboard = $0
      // The keyboard has started sliding away; the sheet rises into its place.
      guard photoPickerAwaitsKeyboardHide, $0.current == 0 else { return }
      photoPickerAwaitsKeyboardHide = false
      isPhotoPickerPresented = true
    }
    .onChange(of: inputIsFocused) { _, isFocused in
      // Tapping the text field trades the sheet for the keyboard.
      guard isFocused else { return }
      isPhotoPickerPresented = false
      photoPickerAwaitsKeyboardHide = false
    }
    .task(id: [isPhotoPickerPresented, photoPickerAwaitsKeyboardHide]) {
      guard !isPhotoPickerPresented, !photoPickerAwaitsKeyboardHide, composerHold > 0 else {
        return
      }
      // Returning to the text field: keep the composer's space until the
      // keyboard has taken it over. If no keyboard arrives (a hardware
      // keyboard, or the sheet was swiped away), the composer settles down.
      if inputIsFocused {
        try? await Task.sleep(for: .milliseconds(600))
        guard !Task.isCancelled else { return }
      }
      withAnimation(.smooth(duration: 0.25)) { composerHold = 0 }
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
  /// back into its source. The composer holds its place while the keyboard
  /// slides away, and the sheet follows once the keyboard has hidden.
  private func showPhotoPickerIfRequested() {
    guard showsPhotoPickerAfterMenu else { return }
    showsPhotoPickerAfterMenu = false
    composerHold = keyboardHeight
    if keyboard.current > 0 {
      photoPickerAwaitsKeyboardHide = true
      inputIsFocused = false
    } else {
      isPhotoPickerPresented = true
    }
  }
}

#Preview {
  NavigationStack { MessagesDemoView() }
}
