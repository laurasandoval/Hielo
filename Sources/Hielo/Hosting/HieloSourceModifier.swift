import SwiftUI

extension View {
  func hieloSource(_ source: HieloSource) -> some View {
    background(HieloSourceReader(source: source))
  }
}
