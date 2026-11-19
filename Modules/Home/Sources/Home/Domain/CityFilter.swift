import Foundation
import Restaurant

public enum CityFilter {
  public static func cities(in restaurants: [RestaurantModel]) -> [String] {
    var seen = Set<String>()
    return restaurants
      .map { $0.city.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty && seen.insert($0.lowercased()).inserted }
      .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
  }

  public static func apply(city: String?, to restaurants: [RestaurantModel]) -> [RestaurantModel] {
    guard let city else {
      return restaurants
    }
    let wanted = key(of: city)
    return restaurants.filter { key(of: $0.city) == wanted }
  }

  private static func key(of city: String) -> String {
    city.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
  }
}
