import Foundation

public struct RestaurantModel: Equatable, Identifiable {
  public let id: String
  public let name: String
  public let city: String
  public let summary: String
  public let rating: Double
  public let imageURL: URL?

  public init(id: String, name: String, city: String, summary: String, rating: Double, imageURL: URL?) {
    self.id = id
    self.name = name
    self.city = city
    self.summary = summary
    self.rating = rating
    self.imageURL = imageURL
  }
}
