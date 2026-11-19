import Foundation
import Restaurant

extension RestaurantModel {
  static func sample(id: String = "r1", name: String? = nil, city: String = "Medan") -> RestaurantModel {
    RestaurantModel(
      id: id,
      name: name ?? "Warung \(id)",
      city: city,
      summary: "Masakan rumahan \(id)",
      rating: 4.3,
      imageURL: URL(string: "https://restaurant-api.dicoding.dev/images/medium/p-\(id)")
    )
  }
}

extension RestaurantEntity {
  static func sample(id: String = "r1", sortIndex: Int = 0, city: String = "Medan") -> RestaurantEntity {
    RestaurantEntity(
      id: id,
      name: "Warung \(id)",
      city: city,
      summary: "Masakan rumahan \(id)",
      rating: 4.3,
      pictureId: "p-\(id)",
      sortIndex: sortIndex,
      isFavorite: false,
      favoritedAt: nil
    )
  }
}

extension RestaurantResponse {
  static func sample(id: String = "r1", name: String? = nil, city: String = "Medan") -> RestaurantResponse {
    RestaurantResponse(
      id: id,
      name: name ?? "Warung \(id)",
      description: "Masakan rumahan \(id)",
      pictureId: "p-\(id)",
      city: city,
      rating: 4.3
    )
  }
}
