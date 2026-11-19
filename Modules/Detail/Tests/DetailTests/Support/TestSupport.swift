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

extension RestaurantDetailModel {
  static var sample: RestaurantDetailModel {
    RestaurantDetailModel(
      id: "r1",
      name: "Warung r1",
      city: "Medan",
      address: "Jl. Mawar No. 1",
      description: "Masakan rumahan",
      rating: 4.3,
      imageURL: nil,
      categories: ["Jawa", "Sunda"],
      foods: ["Nasi Goreng"],
      drinks: ["Es Teh"],
      reviews: [ReviewModel(name: "Sari", review: "Enak", date: "1 Januari 2026")]
    )
  }
}

extension RestaurantDetailResponse {
  static func sample(id: String = "r1", name: String? = "Warung r1") -> RestaurantDetailResponse {
    RestaurantDetailResponse(
      id: id,
      name: name,
      description: "Masakan rumahan",
      city: "Medan",
      address: "Jl. Mawar No. 1",
      pictureId: "14",
      rating: 4.3,
      categories: [NamedResponse(name: "Jawa")],
      menus: MenusResponse(foods: [NamedResponse(name: "Nasi Goreng")], drinks: [NamedResponse(name: "Es Teh")]),
      customerReviews: [ReviewResponse(name: "Sari", review: "Enak", date: "1 Januari 2026")]
    )
  }
}

extension RestaurantEntity {
  static func sample(id: String = "r1", isFavorite: Bool = false) -> RestaurantEntity {
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

final class StubDetailDataSource: DataSource {
  var result: Result<RestaurantDetailResponse, Error>
  private(set) var requests: [String] = []

  init(result: Result<RestaurantDetailResponse, Error>) {
    self.result = result
  }

  func execute(request: String) -> AnyPublisher<RestaurantDetailResponse, Error> {
    requests.append(request)
    return result.publisher.eraseToAnyPublisher()
  }
}

final class StubLocale: LocaleDataSource {
  var stored: [RestaurantEntity] = []
  var failure: Error?
  private(set) var requestedIds: [String] = []

  func list(request: RestaurantListRequest) -> AnyPublisher<[RestaurantEntity], Error> {
    respond(stored)
  }

  func add(entities: [RestaurantEntity]) -> AnyPublisher<Bool, Error> {
    respond(true)
  }

  func get(id: String) -> AnyPublisher<RestaurantEntity?, Error> {
    requestedIds.append(id)
    return respond(stored.first { $0.id == id })
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
