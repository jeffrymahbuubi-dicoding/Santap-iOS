import Foundation

public struct RestaurantEntity: Equatable {
  public let id: String
  public let name: String
  public let city: String
  public let summary: String
  public let rating: Double
  public let pictureId: String?
  public let sortIndex: Int
  public let isFavorite: Bool
  public let favoritedAt: Date?

  public init(
    id: String,
    name: String,
    city: String,
    summary: String,
    rating: Double,
    pictureId: String?,
    sortIndex: Int,
    isFavorite: Bool,
    favoritedAt: Date?
  ) {
    self.id = id
    self.name = name
    self.city = city
    self.summary = summary
    self.rating = rating
    self.pictureId = pictureId
    self.sortIndex = sortIndex
    self.isFavorite = isFavorite
    self.favoritedAt = favoritedAt
  }
}

public enum RestaurantListRequest {
  case all
  case favorites
}

public enum StoreLocation {
  case standard
  case inMemory
  case file(URL)
}
