import Alamofire
import Combine
import Foundation

extension Session {
  func decodedPublisher<Value: Decodable>(
    of type: Value.Type,
    from url: String,
    parameters: Parameters? = nil
  ) -> AnyPublisher<Value, Error> {
    Deferred {
      Future { promise in
        self.request(url, parameters: parameters)
          .validate()
          .responseDecodable(of: type) { response in
            switch response.result {
            case .success(let value):
              promise(.success(value))
            case .failure(let error):
              promise(.failure(NetworkError.from(error)))
            }
          }
      }
    }
    .eraseToAnyPublisher()
  }
}
