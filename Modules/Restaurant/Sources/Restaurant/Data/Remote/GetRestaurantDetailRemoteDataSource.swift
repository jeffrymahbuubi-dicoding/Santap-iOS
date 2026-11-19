import Alamofire
import Combine
import SantapCore

public struct GetRestaurantDetailRemoteDataSource: DataSource {
  private let session: Session

  public init(session: Session = AF) {
    self.session = session
  }

  public func execute(request: String) -> AnyPublisher<RestaurantDetailResponse, Error> {
    session.decodedPublisher(of: RestaurantDetailEnvelope.self, from: Endpoints.detail(id: request))
      .tryMap { envelope in
        guard let restaurant = envelope.restaurant else {
          throw NetworkError.notFound
        }
        return restaurant
      }
      .eraseToAnyPublisher()
  }
}
