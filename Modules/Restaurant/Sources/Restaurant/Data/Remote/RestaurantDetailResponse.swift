import Foundation

public struct NamedResponse: Decodable, Equatable {
  public let name: String?

  public init(name: String?) {
    self.name = name
  }
}

public struct MenusResponse: Decodable, Equatable {
  public let foods: [NamedResponse]?
  public let drinks: [NamedResponse]?

  public init(foods: [NamedResponse]?, drinks: [NamedResponse]?) {
    self.foods = foods
    self.drinks = drinks
  }
}

public struct ReviewResponse: Decodable, Equatable {
  public let name: String?
  public let review: String?
  public let date: String?

  public init(name: String?, review: String?, date: String?) {
    self.name = name
    self.review = review
    self.date = date
  }
}

public struct RestaurantDetailResponse: Decodable, Equatable {
  public let id: String
  public let name: String?
  public let description: String?
  public let city: String?
  public let address: String?
  public let pictureId: String?
  public let rating: Double?
  public let categories: [NamedResponse]?
  public let menus: MenusResponse?
  public let customerReviews: [ReviewResponse]?

  public init(
    id: String,
    name: String?,
    description: String?,
    city: String?,
    address: String?,
    pictureId: String?,
    rating: Double?,
    categories: [NamedResponse]?,
    menus: MenusResponse?,
    customerReviews: [ReviewResponse]?
  ) {
    self.id = id
    self.name = name
    self.description = description
    self.city = city
    self.address = address
    self.pictureId = pictureId
    self.rating = rating
    self.categories = categories
    self.menus = menus
    self.customerReviews = customerReviews
  }
}

struct RestaurantDetailEnvelope: Decodable {
  let error: Bool?
  let message: String?
  let restaurant: RestaurantDetailResponse?
}
