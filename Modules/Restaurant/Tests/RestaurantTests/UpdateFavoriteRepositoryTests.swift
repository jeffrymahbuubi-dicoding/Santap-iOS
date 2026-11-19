import XCTest
@testable import Restaurant

final class UpdateFavoriteRepositoryTests: XCTestCase {
  func testTurningOnPassesAFavouriteEntityNotInTheListToTheLocale() {
    let locale = MockLocaleDataSource()
    let repository = UpdateFavoriteRepository(locale: locale, mapper: RestaurantMapper())

    let result = awaitValue(repository.execute(request: FavoriteUpdate(restaurant: .sample(id: "a"), isFavorite: true)))

    XCTAssertEqual(result, true)
    XCTAssertEqual(locale.updates.count, 1)
    XCTAssertEqual(locale.updates.first?.id, "a")
    XCTAssertEqual(locale.updates.first?.entity.id, "a")
    XCTAssertEqual(locale.updates.first?.entity.name, "Warung a")
    XCTAssertEqual(locale.updates.first?.entity.pictureId, "p-a")
    XCTAssertEqual(locale.updates.first?.entity.sortIndex, -1)
    XCTAssertEqual(locale.updates.first?.entity.isFavorite, true)
  }

  func testTurningOffPassesAnEntityThatIsNotFavourite() {
    let locale = MockLocaleDataSource()
    locale.updateResult = false
    let repository = UpdateFavoriteRepository(locale: locale, mapper: RestaurantMapper())

    let update = FavoriteUpdate(restaurant: .sample(id: "a"), isFavorite: false)

    let result = awaitValue(repository.execute(request: update))

    XCTAssertEqual(result, false)
    XCTAssertEqual(locale.updates.first?.entity.isFavorite, false)
  }

  func testLocaleFailureIsPassedThrough() {
    let locale = MockLocaleDataSource()
    locale.failure = DatabaseError.operationFailed
    let repository = UpdateFavoriteRepository(locale: locale, mapper: RestaurantMapper())

    let error = awaitError(repository.execute(request: FavoriteUpdate(restaurant: .sample(), isFavorite: true)))

    XCTAssertEqual(error as? DatabaseError, .operationFailed)
  }

  func testNothingIsStoredUntilSomeoneSubscribes() {
    let locale = RestaurantLocaleDataSource(location: .inMemory)
    let repository = UpdateFavoriteRepository(locale: locale, mapper: RestaurantMapper())

    _ = repository.execute(request: FavoriteUpdate(restaurant: .sample(id: "a"), isFavorite: true))

    XCTAssertEqual(awaitValue(locale.list(request: .favorites)), [])
  }

  func testWorksWithTheRealStoreAndSurvivesARefresh() throws {
    let locale = RestaurantLocaleDataSource(location: .inMemory)
    let mapper = RestaurantMapper()
    let repository = UpdateFavoriteRepository(locale: locale, mapper: mapper)
    let listed = mapper.mapResponsesToEntities([.sample(id: "a"), .sample(id: "b")])
    _ = awaitValue(locale.add(entities: listed))

    XCTAssertEqual(
      awaitValue(repository.execute(request: FavoriteUpdate(restaurant: .sample(id: "a"), isFavorite: true))),
      true
    )
    _ = awaitValue(locale.add(entities: mapper.mapResponsesToEntities([.sample(id: "c")])))

    XCTAssertEqual(awaitValue(locale.list(request: .all))?.map(\.id), ["c"])
    XCTAssertEqual(awaitValue(locale.list(request: .favorites))?.map(\.id), ["a"])
    XCTAssertEqual(
      awaitValue(repository.execute(request: FavoriteUpdate(restaurant: .sample(id: "a"), isFavorite: false))),
      false
    )
    XCTAssertEqual(awaitValue(locale.list(request: .favorites)), [])
  }
}
