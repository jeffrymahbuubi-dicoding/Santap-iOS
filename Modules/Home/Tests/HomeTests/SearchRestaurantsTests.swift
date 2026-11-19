import Restaurant
import XCTest
@testable import Home

final class SearchRestaurantsRepositoryTests: XCTestCase {
  func testSearchGoesToTheRemoteAndMaps() {
    let remote = StubDataSource<String, [RestaurantResponse]>(.success([.sample(id: "s1", city: "Bali")]))
    let repository = SearchRestaurantsRepository(remote: remote, mapper: RestaurantMapper())

    let models = awaitValue(repository.execute(request: "kafe"))

    XCTAssertEqual(remote.requests, ["kafe"])
    XCTAssertEqual(models?.map(\.id), ["s1"])
    XCTAssertEqual(models?.map(\.city), ["Bali"])
  }

  func testNamelessResponsesAreDropped() {
    let remote = StubDataSource<String, [RestaurantResponse]>(
      .success([.sample(id: "x", name: "  "), .sample(id: "y")])
    )
    let repository = SearchRestaurantsRepository(remote: remote, mapper: RestaurantMapper())

    XCTAssertEqual(awaitValue(repository.execute(request: "a"))?.map(\.id), ["y"])
  }

  func testFailureIsPassedThrough() {
    let remote = StubDataSource<String, [RestaurantResponse]>(.failure(NetworkError.noConnection))
    let repository = SearchRestaurantsRepository(remote: remote, mapper: RestaurantMapper())

    XCTAssertEqual(awaitError(repository.execute(request: "x")) as? NetworkError, .noConnection)
  }
}

final class SearchRestaurantsInteractorTests: XCTestCase {
  private let search = StubRepository<String, [RestaurantModel]>(.success([]))
  private let list = StubRepository<RestaurantListPolicy, [RestaurantModel]>(.success([]))

  private var interactor: SearchRestaurantsInteractor {
    SearchRestaurantsInteractor(search: search, list: list)
  }

  func testTextIsTrimmedBeforeSearching() {
    search.result = .success([.sample(id: "kafe")])

    let result = awaitValue(interactor.execute(request: "  kafe  "))

    XCTAssertEqual(result?.map(\.id), ["kafe"])
    XCTAssertEqual(search.requests, ["kafe"])
    XCTAssertTrue(list.requests.isEmpty)
  }

  func testBlankTextReturnsTheCachedList() {
    list.result = .success([.sample(id: "all")])

    let result = awaitValue(interactor.execute(request: ""))

    XCTAssertEqual(result?.map(\.id), ["all"])
    XCTAssertEqual(list.requests, [.cached])
    XCTAssertTrue(search.requests.isEmpty)
  }

  func testSpacesOnlyReturnTheCachedList() {
    list.result = .success([.sample(id: "all")])

    _ = awaitValue(interactor.execute(request: " \n  "))

    XCTAssertEqual(list.requests, [.cached])
    XCTAssertTrue(search.requests.isEmpty)
  }

  func testSearchErrorPassesThrough() {
    search.result = .failure(TestError.failed)

    XCTAssertEqual(awaitError(interactor.execute(request: "kafe")) as? TestError, .failed)
  }

  func testListErrorPassesThrough() {
    list.result = .failure(TestError.failed)

    XCTAssertEqual(awaitError(interactor.execute(request: "")) as? TestError, .failed)
  }
}
