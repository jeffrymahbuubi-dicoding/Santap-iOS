import Combine
import Foundation
import SantapCore
@testable import Restaurant

enum JSONFixture {
  static func data(_ name: String) throws -> Data {
    guard let url = Bundle.module.url(forResource: name, withExtension: "json") else {
      throw TestError.noValue
    }
    return try Data(contentsOf: url)
  }

  static func decode<Value: Decodable>(_ type: Value.Type, from name: String) throws -> Value {
    try JSONDecoder().decode(type, from: data(name))
  }
}

extension RestaurantEntity {
  static func sample(
    id: String = "r1",
    sortIndex: Int = 0,
    isFavorite: Bool = false,
    favoritedAt: Date? = nil
  ) -> RestaurantEntity {
    RestaurantEntity(
      id: id,
      name: "Warung \(id)",
      city: "Medan",
      summary: "Masakan rumahan \(id)",
      rating: 4.3,
      pictureId: "p-\(id)",
      sortIndex: sortIndex,
      isFavorite: isFavorite,
      favoritedAt: favoritedAt
    )
  }
}

extension RestaurantResponse {
  static func sample(id: String = "r1", name: String? = nil) -> RestaurantResponse {
    RestaurantResponse(
      id: id,
      name: name ?? "Warung \(id)",
      description: "Masakan rumahan \(id)",
      pictureId: "p-\(id)",
      city: "Medan",
      rating: 4.3
    )
  }
}

extension RestaurantModel {
  static func sample(id: String = "r1") -> RestaurantModel {
    RestaurantModel(
      id: id,
      name: "Warung \(id)",
      city: "Medan",
      summary: "Masakan rumahan \(id)",
      rating: 4.3,
      imageURL: URL(string: "https://restaurant-api.dicoding.dev/images/medium/p-\(id)")
    )
  }
}

final class MockLocaleDataSource: LocaleDataSource {
  var failure: Error?
  var updateResult = true

  private(set) var updates: [(id: String, entity: RestaurantEntity)] = []

  func list(request: RestaurantListRequest) -> AnyPublisher<[RestaurantEntity], Error> {
    publisher([])
  }

  func add(entities: [RestaurantEntity]) -> AnyPublisher<Bool, Error> {
    publisher(true)
  }

  func get(id: String) -> AnyPublisher<RestaurantEntity?, Error> {
    publisher(nil)
  }

  func update(id: String, entity: RestaurantEntity) -> AnyPublisher<Bool, Error> {
    updates.append((id, entity))
    return publisher(updateResult)
  }

  private func publisher<Value>(_ value: Value) -> AnyPublisher<Value, Error> {
    if let failure {
      return Fail(error: failure).eraseToAnyPublisher()
    }
    return Just(value).setFailureType(to: Error.self).eraseToAnyPublisher()
  }
}

class StubURLProtocol: URLProtocol {
  enum Reply {
    case response(status: Int, body: Data)
    case failure(URLError.Code)
  }

  static var reply: Reply = .response(status: 200, body: Data())
  static private(set) var requests: [URLRequest] = []

  static func reset() {
    reply = .response(status: 200, body: Data())
    requests = []
  }

  static var configuration: URLSessionConfiguration {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [StubURLProtocol.self]
    return configuration
  }

  override class func canInit(with request: URLRequest) -> Bool { true }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    Self.requests.append(request)
    switch Self.reply {
    case .response(let status, let body):
      guard let url = request.url,
        let response = HTTPURLResponse(
          url: url,
          statusCode: status,
          httpVersion: nil,
          headerFields: ["Content-Type": "application/json"]
        )
      else {
        client?.urlProtocol(self, didFailWithError: URLError(.badURL))
        return
      }
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: body)
      client?.urlProtocolDidFinishLoading(self)
    case .failure(let code):
      client?.urlProtocol(self, didFailWithError: URLError(code))
    }
  }

  override func stopLoading() {}
}
