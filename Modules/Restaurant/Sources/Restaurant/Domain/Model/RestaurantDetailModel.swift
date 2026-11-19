import Foundation

public struct RestaurantDetailModel: Equatable, Identifiable {
  public let id: String
  public let name: String
  public let city: String
  public let address: String
  public let description: String
  public let rating: Double
  public let imageURL: URL?
  public let categories: [String]
  public let foods: [String]
  public let drinks: [String]
  public let reviews: [ReviewModel]

  public init(
    id: String,
    name: String,
    city: String,
    address: String,
    description: String,
    rating: Double,
    imageURL: URL?,
    categories: [String],
    foods: [String],
    drinks: [String],
    reviews: [ReviewModel]
  ) {
    self.id = id
    self.name = name
    self.city = city
    self.address = address
    self.description = description
    self.rating = rating
    self.imageURL = imageURL
    self.categories = categories
    self.foods = foods
    self.drinks = drinks
    self.reviews = reviews
  }
}
