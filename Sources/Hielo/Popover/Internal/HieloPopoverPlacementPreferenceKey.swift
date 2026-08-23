import SwiftUI

struct HieloPopoverPlacementPreferenceKey: PreferenceKey {
  static let defaultValue = HieloPopoverPlacement.source

  static func reduce(
    value: inout HieloPopoverPlacement,
    nextValue: () -> HieloPopoverPlacement
  ) {
    value = nextValue()
  }
}
