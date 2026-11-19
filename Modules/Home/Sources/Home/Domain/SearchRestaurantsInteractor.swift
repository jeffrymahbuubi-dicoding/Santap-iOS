import Combine
import Foundation
import Restaurant
import SantapCore

public struct SearchRestaurantsInteractor: UseCase {
  private let search: any Repository<String, [RestaurantModel]>
  private let list: any Repository<RestaurantListPolicy, [RestaurantModel]>

  public init(
    search: any Repository<String, [RestaurantModel]>,
    list: any Repository<RestaurantListPolicy, [RestaurantModel]>
  ) {
    self.search = search
    self.list = list
  }

  public func execute(request: String) -> AnyPublisher<[RestaurantModel], Error> {
    let keyword = request.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !keyword.isEmpty else {
      return list.execute(request: .cached)
    }
    return search.execute(request: keyword)
  }
}
