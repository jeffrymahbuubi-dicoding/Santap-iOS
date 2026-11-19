import Combine
import SantapCore

public struct FavoriteUpdate: Equatable {
  public let restaurant: RestaurantModel
  public let isFavorite: Bool

  public init(restaurant: RestaurantModel, isFavorite: Bool) {
    self.restaurant = restaurant
    self.isFavorite = isFavorite
  }
}

public struct UpdateFavoriteRepository: Repository {
  private let locale: any LocaleDataSource<RestaurantListRequest, RestaurantEntity>
  private let mapper: RestaurantMapper

  public init(locale: any LocaleDataSource<RestaurantListRequest, RestaurantEntity>, mapper: RestaurantMapper) {
    self.locale = locale
    self.mapper = mapper
  }

  public func execute(request: FavoriteUpdate) -> AnyPublisher<Bool, Error> {
    let stored = mapper.mapDomainToEntity(request.restaurant)
    let entity = RestaurantEntity(
      id: stored.id,
      name: stored.name,
      city: stored.city,
      summary: stored.summary,
      rating: stored.rating,
      pictureId: stored.pictureId,
      sortIndex: stored.sortIndex,
      isFavorite: request.isFavorite,
      favoritedAt: nil
    )
    return locale.update(id: entity.id, entity: entity)
  }
}
