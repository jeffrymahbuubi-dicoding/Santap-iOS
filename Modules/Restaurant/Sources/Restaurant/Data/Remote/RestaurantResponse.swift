import Foundation

public struct RestaurantResponse: Decodable, Equatable {
  public let id: String
  public let name: String?
  public let description: String?
  public let pictureId: String?
  public let city: String?
  public let rating: Double?

  public init(
    id: String,
    name: String?,
    description: String?,
    pictureId: String?,
    city: String?,
    rating: Double?
  ) {
    self.id = id
    self.name = name
    self.description = description
    self.pictureId = pictureId
    self.city = city
    self.rating = rating
  }
}

struct RestaurantListResponse: Decodable {
  let error: Bool?
  let message: String?
  let count: Int?
  let restaurants: [RestaurantResponse]?
}

struct RestaurantSearchResponse: Decodable {
  let error: Bool?
  let founded: Int?
  let restaurants: [RestaurantResponse]?
}
