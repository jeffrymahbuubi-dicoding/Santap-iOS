import Combine
import Foundation
import SantapCore
@testable import About

struct StubProfileDataSource: DataSource {
  let result: Result<ProfileEntity, Error>

  func execute(request: Void) -> AnyPublisher<ProfileEntity, Error> {
    result.publisher.eraseToAnyPublisher()
  }
}
