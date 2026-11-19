import Combine
import XCTest

enum TestError: Error, Equatable {
  case noValue
  case failed
}

extension XCTestCase {
  func awaitResult<Output>(
    _ publisher: AnyPublisher<Output, Error>,
    timeout: TimeInterval = 2
  ) -> Result<Output, Error> {
    var received: Result<Output, Error> = .failure(TestError.noValue)
    let finished = expectation(description: "publisher completes")
    let cancellable = publisher.sink(
      receiveCompletion: { completion in
        if case .failure(let error) = completion {
          received = .failure(error)
        }
        finished.fulfill()
      },
      receiveValue: { value in
        received = .success(value)
      }
    )
    wait(for: [finished], timeout: timeout)
    cancellable.cancel()
    return received
  }

  func awaitValue<Output>(_ publisher: AnyPublisher<Output, Error>, timeout: TimeInterval = 2) -> Output? {
    try? awaitResult(publisher, timeout: timeout).get()
  }

  func awaitError<Output>(_ publisher: AnyPublisher<Output, Error>, timeout: TimeInterval = 2) -> Error? {
    if case .failure(let error) = awaitResult(publisher, timeout: timeout) {
      return error
    }
    return nil
  }

  func spin(until condition: () -> Bool, timeout: TimeInterval = 2) {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition(), Date() < deadline {
      RunLoop.main.run(until: Date().addingTimeInterval(0.01))
    }
  }

  func spin(for seconds: TimeInterval) {
    RunLoop.main.run(until: Date().addingTimeInterval(seconds))
  }
}
