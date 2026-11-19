import Combine
import Foundation
import Restaurant
import SantapCore

public struct GetRestaurantDetailRepository: Repository {
  private let remote: any DataSource<String, RestaurantDetailResponse>
  private let mapper: RestaurantMapper

  public init(remote: any DataSource<String, RestaurantDetailResponse>, mapper: RestaurantMapper) {
    self.remote = remote
    self.mapper = mapper
  }

  public func execute(request: String) -> AnyPublisher<RestaurantDetailModel, Error> {
    let mapper = mapper
    return remote.execute(request: request)
      .tryMap { response in
        guard let detail = mapper.mapDetailResponseToDomain(response) else {
          throw NetworkError.invalidData
        }
        return detail
      }
      .eraseToAnyPublisher()
  }
}
