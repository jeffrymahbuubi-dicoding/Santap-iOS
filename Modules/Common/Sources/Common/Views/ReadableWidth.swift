import SwiftUI

private struct ReadableWidth: ViewModifier {
  func body(content: Content) -> some View {
    content
      .frame(maxWidth: 600)
      .frame(maxWidth: .infinity)
  }
}

public extension View {
  func readableWidth() -> some View {
    modifier(ReadableWidth())
  }
}
