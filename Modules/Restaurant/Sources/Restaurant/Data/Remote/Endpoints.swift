import Foundation

enum Endpoints {
  static let base = "https://restaurant-api.dicoding.dev"

  static var list: String { base + "/list" }
  static var search: String { base + "/search" }

  static func detail(id: String) -> String {
    base + "/detail/" + id
  }

  static func image(pictureId: String) -> String {
    base + "/images/medium/" + pictureId
  }
}
