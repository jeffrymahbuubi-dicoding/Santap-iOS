import Restaurant
import SantapCore
import XCTest
@testable import Home

final class GetRestaurantsRepositoryTests: XCTestCase {
  private var remote = StubDataSource<Void, [RestaurantResponse]>(.success([]))
  private var locale = StubLocaleDataSource()

  override func setUp() {
    super.setUp()
    remote = StubDataSource(.success([]))
    locale = StubLocaleDataSource()
  }

  private func makeRepository(locale: (any LocaleDataSource<RestaurantListRequest, RestaurantEntity>)? = nil)
    -> GetRestaurantsRepository {
    GetRestaurantsRepository(locale: locale ?? self.locale, remote: remote, mapper: RestaurantMapper())
  }

  func testCacheHitNeverCallsTheRemote() {
    locale.stored = [.sample(id: "a")]

    let models = awaitValue(makeRepository().execute(request: .cached))

    XCTAssertEqual(models?.map(\.id), ["a"])
    XCTAssertTrue(remote.requests.isEmpty)
    XCTAssertEqual(locale.calls, ["list"])
  }

  func testEmptyCacheCallsRemoteThenSavesThenReads() {
    remote.result = .success([.sample(id: "a"), .sample(id: "b")])

    let models = awaitValue(makeRepository().execute(request: .cached))

    XCTAssertEqual(models?.map(\.id), ["a", "b"])
    XCTAssertEqual(remote.requests.count, 1)
    XCTAssertEqual(locale.calls, ["list", "add", "list"])
    XCTAssertEqual(locale.added.first?.map(\.sortIndex), [0, 1])
  }

  func testEmptyCacheAndRemoteFailurePassesTheErrorThrough() {
    remote.result = .failure(NetworkError.noConnection)

    let error = awaitError(makeRepository().execute(request: .cached))

    XCTAssertEqual(error as? NetworkError, .noConnection)
    XCTAssertEqual(locale.calls, ["list"])
  }

  func testRefreshAlwaysUsesTheRemote() {
    locale.stored = [.sample(id: "old")]
    remote.result = .success([.sample(id: "new")])

    let models = awaitValue(makeRepository().execute(request: .refresh))

    XCTAssertEqual(models?.map(\.id), ["new"])
    XCTAssertEqual(remote.requests.count, 1)
    XCTAssertEqual(locale.calls, ["add", "list"])
  }

  func testRefreshFailureKeepsTheCache() {
    locale.stored = [.sample(id: "old")]
    remote.result = .failure(NetworkError.server(500))

    let error = awaitError(makeRepository().execute(request: .refresh))

    XCTAssertEqual(error as? NetworkError, .server(500))
    XCTAssertEqual(locale.stored.map(\.id), ["old"])
    XCTAssertTrue(locale.added.isEmpty)
  }

  func testLocaleFailureIsPassedThrough() {
    locale.failure = DatabaseError.operationFailed

    let error = awaitError(makeRepository().execute(request: .cached))

    XCTAssertEqual(error as? DatabaseError, .operationFailed)
    XCTAssertTrue(remote.requests.isEmpty)
  }

  func testRefreshKeepsAFavouriteWithARealStore() throws {
    let store = RestaurantLocaleDataSource(location: .inMemory)
    let repository = makeRepository(locale: store)
    remote.result = .success([.sample(id: "a"), .sample(id: "b")])
    _ = awaitValue(repository.execute(request: .cached))
    let favourite = RestaurantEntity(
      id: "a", name: "Warung a", city: "Medan", summary: "Masakan rumahan a",
      rating: 4.3, pictureId: "p-a", sortIndex: -1, isFavorite: true, favoritedAt: nil
    )
    _ = awaitValue(store.update(id: "a", entity: favourite))

    remote.result = .success([.sample(id: "a", name: "Nama Baru"), .sample(id: "c")])
    let refreshed = awaitValue(repository.execute(request: .refresh))

    XCTAssertEqual(refreshed?.map(\.name), ["Nama Baru", "Warung c"])
    XCTAssertEqual(awaitValue(store.list(request: .favorites))?.map(\.id), ["a"])
  }
}
