import SwiftUI

struct HieloPopoverCornerRadiusPreferenceKey: PreferenceKey {
  static let defaultValue: HieloPopoverCornerRadius? = nil

  static func reduce(
    value: inout HieloPopoverCornerRadius?,
    nextValue: () -> HieloPopoverCornerRadius?
  ) {
    value = nextValue() ?? value
  }
}
