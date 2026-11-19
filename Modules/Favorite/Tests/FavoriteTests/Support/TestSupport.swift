import Combine
import Foundation
import Restaurant
import SantapCore

extension RestaurantModel {
  static func sample(id: String = "r1") -> RestaurantModel {
    RestaurantModel(
      id: id,
      name: "Warung \(id)",
      city: "Medan",
      summary: "Masakan rumahan \(id)",
      rating: 4.3,
      imageURL: nil
    )
  }
}

extension RestaurantEntity {
  static func sample(id: String, isFavorite: Bool = true) -> RestaurantEntity {
    RestaurantEntity(
      id: id,
      name: "Warung \(id)",
      city: "Medan",
      summary: "Masakan rumahan \(id)",
      rating: 4.3,
      pictureId: nil,
      sortIndex: 0,
      isFavorite: isFavorite,
      favoritedAt: nil
    )
  }
}

final class StubUseCase<Request, Response>: UseCase {
  private let handler: (Request) -> Result<Response, Error>
  private(set) var requests: [Request] = []

  init(handler: @escaping (Request) -> Result<Response, Error>) {
    self.handler = handler
  }

  convenience init(result: Result<Response, Error>) {
    self.init(handler: { _ in result })
  }

  func execute(request: Request) -> AnyPublisher<Response, Error> {
    requests.append(request)
    return handler(request).publisher.eraseToAnyPublisher()
  }
}

final class StubLocale: LocaleDataSource {
  var stored: [RestaurantEntity] = []
  var failure: Error?
  private(set) var listRequests: [RestaurantListRequest] = []

  func list(request: RestaurantListRequest) -> AnyPublisher<[RestaurantEntity], Error> {
    listRequests.append(request)
    return respond(stored)
  }

  func add(entities: [RestaurantEntity]) -> AnyPublisher<Bool, Error> {
    respond(true)
  }

  func get(id: String) -> AnyPublisher<RestaurantEntity?, Error> {
    respond(stored.first { $0.id == id })
  }

  func update(id: String, entity: RestaurantEntity) -> AnyPublisher<Bool, Error> {
    respond(entity.isFavorite)
  }

  private func respond<Value>(_ value: Value) -> AnyPublisher<Value, Error> {
    if let failure {
      return Fail(error: failure).eraseToAnyPublisher()
    }
    return Just(value).setFailureType(to: Error.self).eraseToAnyPublisher()
  }
}
