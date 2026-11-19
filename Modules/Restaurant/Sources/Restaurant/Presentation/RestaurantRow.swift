import Common
import SwiftUI

public struct RestaurantRow: View {
  private let restaurant: RestaurantModel

  public init(restaurant: RestaurantModel) {
    self.restaurant = restaurant
  }

  public var body: some View {
    HStack(spacing: 12) {
      RemoteImageView(url: restaurant.imageURL)
        .frame(width: 88, height: 88)
        .clipShape(RoundedRectangle(cornerRadius: 12))
      VStack(alignment: .leading, spacing: 4) {
        Text(restaurant.name)
          .font(.headline)
        Label(restaurant.city, systemImage: "mappin.and.ellipse")
          .font(.subheadline)
          .foregroundStyle(.secondary)
        RatingView(rating: restaurant.rating)
      }
      Spacer(minLength: 0)
    }
    .padding(.vertical, 4)
    .frame(minHeight: 44)
    .accessibilityElement(children: .combine)
  }
}
