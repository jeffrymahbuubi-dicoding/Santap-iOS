import Combine
import Restaurant
import SantapCore

final class StubDataSource<Request, Response>: DataSource {
  var result: Result<Response, Error>
  private(set) var requests: [Request] = []

  init(_ result: Result<Response, Error>) {
    self.result = result
  }

  func execute(request: Request) -> AnyPublisher<Response, Error> {
    requests.append(request)
    return result.publisher.eraseToAnyPublisher()
  }
}

final class StubRepository<Request, Response>: Repository {
  var result: Result<Response, Error>
  private(set) var requests: [Request] = []

  init(_ result: Result<Response, Error>) {
    self.result = result
  }

  func execute(request: Request) -> AnyPublisher<Response, Error> {
    requests.append(request)
    return result.publisher.eraseToAnyPublisher()
  }
}

final class StubUseCase<Request, Response>: UseCase {
  var result: Result<Response, Error>
  private(set) var requests: [Request] = []

  init(_ result: Result<Response, Error>) {
    self.result = result
  }

  func execute(request: Request) -> AnyPublisher<Response, Error> {
    requests.append(request)
    return result.publisher.eraseToAnyPublisher()
  }
}

final class StubLocaleDataSource: LocaleDataSource {
  var stored: [RestaurantEntity] = []
  var failure: Error?
  private(set) var calls: [String] = []
  private(set) var added: [[RestaurantEntity]] = []

  func list(request: RestaurantListRequest) -> AnyPublisher<[RestaurantEntity], Error> {
    calls.append("list")
    return publisher(stored)
  }

  func add(entities: [RestaurantEntity]) -> AnyPublisher<Bool, Error> {
    calls.append("add")
    added.append(entities)
    stored = entities
    return publisher(true)
  }

  func get(id: String) -> AnyPublisher<RestaurantEntity?, Error> {
    calls.append("get")
    return publisher(stored.first { $0.id == id })
  }

  func update(id: String, entity: RestaurantEntity) -> AnyPublisher<Bool, Error> {
    calls.append("update")
    return publisher(true)
  }

  private func publisher<Value>(_ value: Value) -> AnyPublisher<Value, Error> {
    if let failure {
      return Fail(error: failure).eraseToAnyPublisher()
    }
    return Just(value).setFailureType(to: Error.self).eraseToAnyPublisher()
  }
}
