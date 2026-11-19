import SwiftUI

public struct RatingView: View {
  private let rating: Double

  public init(rating: Double) {
    self.rating = rating
  }

  private var text: String {
    rating.formatted(.number.precision(.fractionLength(1)))
  }

  public var body: some View {
    Label {
      Text(text)
    } icon: {
      Image(systemName: "star.fill")
        .foregroundStyle(.orange)
    }
    .font(.subheadline)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("common_rating".localized(text))
  }
}
