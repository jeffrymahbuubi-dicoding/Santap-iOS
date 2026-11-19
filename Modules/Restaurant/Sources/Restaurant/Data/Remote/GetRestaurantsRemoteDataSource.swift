import Alamofire
import Combine
import SantapCore

public struct GetRestaurantsRemoteDataSource: DataSource {
  private let session: Session

  public init(session: Session = AF) {
    self.session = session
  }

  public func execute(request: Void) -> AnyPublisher<[RestaurantResponse], Error> {
    session.decodedPublisher(of: RestaurantListResponse.self, from: Endpoints.list)
      .map { $0.restaurants ?? [] }
      .eraseToAnyPublisher()
  }
}
