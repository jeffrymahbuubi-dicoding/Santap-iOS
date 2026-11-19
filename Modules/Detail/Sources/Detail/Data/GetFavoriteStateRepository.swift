import Combine
import Foundation
import Restaurant
import SantapCore

public struct GetFavoriteStateRepository: Repository {
  private let locale: any LocaleDataSource<RestaurantListRequest, RestaurantEntity>

  public init(locale: any LocaleDataSource<RestaurantListRequest, RestaurantEntity>) {
    self.locale = locale
  }

  public func execute(request: String) -> AnyPublisher<Bool, Error> {
    locale.get(id: request)
      .map { $0?.isFavorite ?? false }
      .eraseToAnyPublisher()
  }
}
