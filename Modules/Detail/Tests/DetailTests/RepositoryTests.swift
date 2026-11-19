import Restaurant
import SantapCore
import XCTest
@testable import Detail

final class GetRestaurantDetailRepositoryTests: XCTestCase {
  func testMapsTheResponseToTheDomainModelAndForwardsTheId() {
    let remote = StubDetailDataSource(result: .success(.sample(id: "abc")))
    let sut = GetRestaurantDetailRepository(remote: remote, mapper: RestaurantMapper())

    let detail = awaitValue(sut.execute(request: "abc"))

    XCTAssertEqual(remote.requests, ["abc"])
    XCTAssertEqual(detail?.id, "abc")
    XCTAssertEqual(detail?.name, "Warung r1")
    XCTAssertEqual(detail?.foods, ["Nasi Goreng"])
    XCTAssertEqual(detail?.drinks, ["Es Teh"])
    XCTAssertEqual(detail?.reviews.map(\.name), ["Sari"])
  }

  func testAResponseWithoutANameFailsAsInvalidData() {
    let remote = StubDetailDataSource(result: .success(.sample(name: nil)))
    let sut = GetRestaurantDetailRepository(remote: remote, mapper: RestaurantMapper())

    let error = awaitError(sut.execute(request: "r1"))

    XCTAssertEqual(error as? NetworkError, .invalidData)
  }

  func testRemoteErrorsPassThrough() {
    let remote = StubDetailDataSource(result: .failure(NetworkError.noConnection))
    let sut = GetRestaurantDetailRepository(remote: remote, mapper: RestaurantMapper())

    let error = awaitError(sut.execute(request: "r1"))

    XCTAssertEqual(error as? NetworkError, .noConnection)
  }
}

final class GetFavoriteStateRepositoryTests: XCTestCase {
  func testStoredFavoriteIsTrue() {
    let locale = StubLocale()
    locale.stored = [.sample(id: "a", isFavorite: true)]

    let state = awaitValue(GetFavoriteStateRepository(locale: locale).execute(request: "a"))

    XCTAssertEqual(state, true)
    XCTAssertEqual(locale.requestedIds, ["a"])
  }

  func testStoredNonFavoriteIsFalse() {
    let locale = StubLocale()
    locale.stored = [.sample(id: "a", isFavorite: false)]

    let state = awaitValue(GetFavoriteStateRepository(locale: locale).execute(request: "a"))

    XCTAssertEqual(state, false)
  }

  func testUnknownIdIsFalse() {
    let state = awaitValue(GetFavoriteStateRepository(locale: StubLocale()).execute(request: "missing"))

    XCTAssertEqual(state, false)
  }

  func testStoreErrorsPassThrough() {
    let locale = StubLocale()
    locale.failure = DatabaseError.operationFailed

    let error = awaitError(GetFavoriteStateRepository(locale: locale).execute(request: "a"))

    XCTAssertEqual(error as? DatabaseError, .operationFailed)
  }

  func testStateFollowsTheRealStoreAfterAnUpdate() {
    let store = RestaurantLocaleDataSource(location: .inMemory)
    let update = UpdateFavoriteRepository(locale: store, mapper: RestaurantMapper())
    let sut = GetFavoriteStateRepository(locale: store)
    let restaurant = RestaurantModel.sample(id: "kept")
    let turnOn = FavoriteUpdate(restaurant: restaurant, isFavorite: true)
    let turnOff = FavoriteUpdate(restaurant: restaurant, isFavorite: false)

    XCTAssertEqual(awaitValue(sut.execute(request: "kept")), false)
    XCTAssertEqual(awaitValue(update.execute(request: turnOn)), true)
    XCTAssertEqual(awaitValue(sut.execute(request: "kept")), true)
    XCTAssertEqual(awaitValue(update.execute(request: turnOff)), false)
    XCTAssertEqual(awaitValue(sut.execute(request: "kept")), false)
  }
}
