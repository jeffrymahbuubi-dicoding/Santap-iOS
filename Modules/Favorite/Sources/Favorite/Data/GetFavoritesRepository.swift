import Combine
import Foundation
import Restaurant
import SantapCore

public struct GetFavoritesRepository: Repository {
  private let locale: any LocaleDataSource<RestaurantListRequest, RestaurantEntity>
  private let mapper: RestaurantMapper

  public init(locale: any LocaleDataSource<RestaurantListRequest, RestaurantEntity>, mapper: RestaurantMapper) {
    self.locale = locale
    self.mapper = mapper
  }

  public func execute(request: Void) -> AnyPublisher<[RestaurantModel], Error> {
    let mapper = mapper
    return locale.list(request: .favorites)
      .map { mapper.mapEntitiesToDomains($0) }
      .eraseToAnyPublisher()
  }
}
