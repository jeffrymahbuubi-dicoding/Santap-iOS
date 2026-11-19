import Combine
import Restaurant
import SantapCore

public struct SearchRestaurantsRepository: Repository {
  private let remote: any DataSource<String, [RestaurantResponse]>
  private let mapper: RestaurantMapper

  public init(remote: any DataSource<String, [RestaurantResponse]>, mapper: RestaurantMapper) {
    self.remote = remote
    self.mapper = mapper
  }

  public func execute(request: String) -> AnyPublisher<[RestaurantModel], Error> {
    let mapper = self.mapper
    return remote.execute(request: request)
      .map { mapper.mapResponsesToDomains($0) }
      .eraseToAnyPublisher()
  }
}
