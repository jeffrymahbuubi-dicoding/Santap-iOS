import Combine
import Restaurant
import SantapCore

public struct GetRestaurantsRepository: Repository {
  private let locale: any LocaleDataSource<RestaurantListRequest, RestaurantEntity>
  private let remote: any DataSource<Void, [RestaurantResponse]>
  private let mapper: RestaurantMapper

  public init(
    locale: any LocaleDataSource<RestaurantListRequest, RestaurantEntity>,
    remote: any DataSource<Void, [RestaurantResponse]>,
    mapper: RestaurantMapper
  ) {
    self.locale = locale
    self.remote = remote
    self.mapper = mapper
  }

  public func execute(request: RestaurantListPolicy) -> AnyPublisher<[RestaurantModel], Error> {
    let mapper = self.mapper
    return entities(for: request)
      .map { mapper.mapEntitiesToDomains($0) }
      .eraseToAnyPublisher()
  }

  private func entities(for policy: RestaurantListPolicy) -> AnyPublisher<[RestaurantEntity], Error> {
    switch policy {
    case .refresh:
      return fetchAndStore()
    case .cached:
      let fetch = fetchAndStore
      return locale.list(request: .all)
        .flatMap { stored -> AnyPublisher<[RestaurantEntity], Error> in
          if stored.isEmpty {
            return fetch()
          }
          return Just(stored).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
  }

  private func fetchAndStore() -> AnyPublisher<[RestaurantEntity], Error> {
    let mapper = self.mapper
    let locale = self.locale
    return remote.execute(request: ())
      .map { mapper.mapResponsesToEntities($0) }
      .flatMap { locale.add(entities: $0) }
      .flatMap { _ in locale.list(request: .all) }
      .eraseToAnyPublisher()
  }
}
