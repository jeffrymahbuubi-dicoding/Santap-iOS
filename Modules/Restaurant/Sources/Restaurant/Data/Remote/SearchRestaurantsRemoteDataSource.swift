import Alamofire
import Combine
import SantapCore

public struct SearchRestaurantsRemoteDataSource: DataSource {
  private let session: Session

  public init(session: Session = AF) {
    self.session = session
  }

  public func execute(request: String) -> AnyPublisher<[RestaurantResponse], Error> {
    session.decodedPublisher(of: RestaurantSearchResponse.self, from: Endpoints.search, parameters: ["q": request])
      .map { $0.restaurants ?? [] }
      .eraseToAnyPublisher()
  }
}
