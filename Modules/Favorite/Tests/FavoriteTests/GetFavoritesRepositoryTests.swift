import Restaurant
import XCTest
@testable import Favorite

final class GetFavoritesRepositoryTests: XCTestCase {
  func testAsksTheStoreForFavouritesAndMapsThemToDomainModels() {
    let locale = StubLocale()
    locale.stored = [.sample(id: "b"), .sample(id: "a")]
    let sut = GetFavoritesRepository(locale: locale, mapper: RestaurantMapper())

    let result = awaitValue(sut.execute(request: ()))

    XCTAssertEqual(locale.listRequests.count, 1)
    guard case .favorites = locale.listRequests.first else {
      return XCTFail("expected the favourites request")
    }
    XCTAssertEqual(result?.map(\.id), ["b", "a"])
    XCTAssertEqual(result?.first?.name, "Warung b")
  }

  func testNoFavouritesGivesAnEmptyList() {
    let sut = GetFavoritesRepository(locale: StubLocale(), mapper: RestaurantMapper())

    XCTAssertEqual(awaitValue(sut.execute(request: ()))?.count, 0)
  }

  func testStoreErrorsPassThrough() {
    let locale = StubLocale()
    locale.failure = DatabaseError.unavailable
    let sut = GetFavoritesRepository(locale: locale, mapper: RestaurantMapper())

    XCTAssertEqual(awaitError(sut.execute(request: ())) as? DatabaseError, .unavailable)
  }

  func testNewestFavouriteComesFirstInTheRealStore() {
    let store = RestaurantLocaleDataSource(location: .inMemory)
    let update = UpdateFavoriteRepository(locale: store, mapper: RestaurantMapper())
    let sut = GetFavoritesRepository(locale: store, mapper: RestaurantMapper())

    let older = FavoriteUpdate(restaurant: .sample(id: "old"), isFavorite: true)
    let newer = FavoriteUpdate(restaurant: .sample(id: "new"), isFavorite: true)

    XCTAssertEqual(awaitValue(update.execute(request: older)), true)
    Thread.sleep(forTimeInterval: 0.01)
    XCTAssertEqual(awaitValue(update.execute(request: newer)), true)

    XCTAssertEqual(awaitValue(sut.execute(request: ()))?.map(\.id), ["new", "old"])
  }
}
