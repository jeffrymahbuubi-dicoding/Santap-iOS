import XCTest
@testable import Restaurant

final class RestaurantLocaleDataSourceTests: XCTestCase {
  private var directory: URL?

  override func tearDown() {
    if let directory {
      try? FileManager.default.removeItem(at: directory)
    }
    directory = nil
    super.tearDown()
  }

  func testEmptyStoreReturnsNothing() {
    let locale = RestaurantLocaleDataSource(location: .inMemory)

    XCTAssertEqual(awaitValue(locale.list(request: .all)), [])
    XCTAssertEqual(awaitValue(locale.list(request: .favorites)), [])
    XCTAssertEqual(awaitValue(locale.get(id: "none")).map { $0 == nil }, true)
  }

  func testRestaurantsComeBackInSortIndexOrder() {
    let locale = RestaurantLocaleDataSource(location: .inMemory)
    let entities = [
      RestaurantEntity.sample(id: "c", sortIndex: 2),
      .sample(id: "a", sortIndex: 0),
      .sample(id: "b", sortIndex: 1)
    ]

    XCTAssertEqual(awaitValue(locale.add(entities: entities)), true)

    XCTAssertEqual(awaitValue(locale.list(request: .all))?.map(\.id), ["a", "b", "c"])
  }

  func testUpsertUpdatesFieldsWithoutDuplicates() throws {
    let locale = RestaurantLocaleDataSource(location: .inMemory)
    _ = awaitValue(locale.add(entities: [.sample(id: "a", sortIndex: 0)]))
    let changed = RestaurantEntity(
      id: "a", name: "Nama Baru", city: "Bali", summary: "Baru", rating: 5,
      pictureId: nil, sortIndex: 0, isFavorite: false, favoritedAt: nil
    )

    _ = awaitValue(locale.add(entities: [changed]))

    let stored = try XCTUnwrap(awaitValue(locale.list(request: .all)))
    XCTAssertEqual(stored.count, 1)
    XCTAssertEqual(stored.first?.name, "Nama Baru")
    XCTAssertEqual(stored.first?.rating, 5)
    XCTAssertNil(stored.first?.pictureId)
  }

  func testUpsertKeepsFavouriteFields() throws {
    let locale = RestaurantLocaleDataSource(location: .inMemory)
    _ = awaitValue(locale.add(entities: [.sample(id: "a", sortIndex: 0)]))
    _ = awaitValue(locale.update(id: "a", entity: .sample(id: "a", isFavorite: true)))
    let moment = try XCTUnwrap(awaitValue(locale.get(id: "a")).flatMap { $0?.favoritedAt })

    _ = awaitValue(locale.add(entities: [.sample(id: "a", sortIndex: 3)]))

    let stored = try XCTUnwrap(awaitValue(locale.list(request: .all)).flatMap(\.first))
    XCTAssertTrue(stored.isFavorite)
    XCTAssertEqual(stored.favoritedAt, moment)
    XCTAssertEqual(stored.sortIndex, 3)
  }

  func testStaleRowsAreRemovedButFavouritesStay() {
    let locale = RestaurantLocaleDataSource(location: .inMemory)
    _ = awaitValue(locale.add(entities: [.sample(id: "a", sortIndex: 0), .sample(id: "b", sortIndex: 1)]))
    _ = awaitValue(locale.update(id: "b", entity: .sample(id: "b", isFavorite: true)))

    _ = awaitValue(locale.add(entities: [.sample(id: "c", sortIndex: 0)]))

    XCTAssertEqual(awaitValue(locale.list(request: .all))?.map(\.id), ["c"])
    XCTAssertEqual(awaitValue(locale.list(request: .favorites))?.map(\.id), ["b"])
  }

  func testGetReturnsTheStoredEntityOrNil() throws {
    let locale = RestaurantLocaleDataSource(location: .inMemory)
    _ = awaitValue(locale.add(entities: [.sample(id: "a", sortIndex: 4)]))

    let found = try XCTUnwrap(awaitValue(locale.get(id: "a")).flatMap { $0 })

    XCTAssertEqual(found.id, "a")
    XCTAssertEqual(found.sortIndex, 4)
    XCTAssertEqual(found.name, "Warung a")
    XCTAssertEqual(awaitValue(locale.get(id: "b")).map { $0 == nil }, true)
  }

  func testUpdateTurnsTheFavouriteOnAndOffAndEmitsTheNewState() {
    let locale = RestaurantLocaleDataSource(location: .inMemory)
    _ = awaitValue(locale.add(entities: [.sample(id: "a", sortIndex: 0)]))

    XCTAssertEqual(awaitValue(locale.update(id: "a", entity: .sample(id: "a", isFavorite: true))), true)
    XCTAssertEqual(awaitValue(locale.get(id: "a")).flatMap { $0?.isFavorite }, true)
    XCTAssertEqual(awaitValue(locale.list(request: .favorites))?.map(\.id), ["a"])

    XCTAssertEqual(awaitValue(locale.update(id: "a", entity: .sample(id: "a", isFavorite: false))), false)
    XCTAssertEqual(awaitValue(locale.get(id: "a")).flatMap { $0?.isFavorite }, false)
    XCTAssertEqual(awaitValue(locale.list(request: .favorites)), [])
    XCTAssertEqual(awaitValue(locale.list(request: .all))?.map(\.id), ["a"])
  }

  func testTurningOnSetsTheTimeAndTurningOffClearsIt() {
    let locale = RestaurantLocaleDataSource(location: .inMemory)
    let before = Date()
    _ = awaitValue(locale.add(entities: [.sample(id: "a", sortIndex: 0)]))

    _ = awaitValue(locale.update(id: "a", entity: .sample(id: "a", isFavorite: true)))
    let whileOn = awaitValue(locale.get(id: "a")).flatMap { $0?.favoritedAt }
    _ = awaitValue(locale.update(id: "a", entity: .sample(id: "a", isFavorite: false)))
    let afterOff = awaitValue(locale.get(id: "a")).flatMap { $0?.favoritedAt }

    XCTAssertNotNil(whileOn)
    XCTAssertGreaterThanOrEqual(whileOn ?? .distantPast, before)
    XCTAssertNil(afterOff)
  }

  func testTurningOnTwiceKeepsTheFirstTime() throws {
    let locale = RestaurantLocaleDataSource(location: .inMemory)
    _ = awaitValue(locale.update(id: "a", entity: .sample(id: "a", sortIndex: -1, isFavorite: true)))
    let first = try XCTUnwrap(awaitValue(locale.get(id: "a")).flatMap { $0?.favoritedAt })

    _ = awaitValue(locale.update(id: "a", entity: .sample(id: "a", sortIndex: -1, isFavorite: true)))

    XCTAssertEqual(awaitValue(locale.get(id: "a")).flatMap { $0?.favoritedAt }, first)
  }

  func testTurningOffAnUnknownIdChangesNothing() {
    let locale = RestaurantLocaleDataSource(location: .inMemory)

    XCTAssertEqual(awaitValue(locale.update(id: "ghost", entity: .sample(id: "ghost"))), false)

    XCTAssertEqual(awaitValue(locale.get(id: "ghost")).map { $0 == nil }, true)
  }

  func testFavouriteNotInTheListStaysOutOfTheListAndIsDeletedOnRemoval() {
    let locale = RestaurantLocaleDataSource(location: .inMemory)

    _ = awaitValue(locale.update(id: "z", entity: .sample(id: "z", sortIndex: -1, isFavorite: true)))

    XCTAssertEqual(awaitValue(locale.list(request: .all)), [])
    XCTAssertEqual(awaitValue(locale.list(request: .favorites))?.map(\.id), ["z"])

    _ = awaitValue(locale.update(id: "z", entity: .sample(id: "z", sortIndex: -1)))

    XCTAssertEqual(awaitValue(locale.list(request: .favorites)), [])
    XCTAssertEqual(awaitValue(locale.get(id: "z")).map { $0 == nil }, true)
  }

  func testFavouritesAreNewestFirst() {
    let locale = RestaurantLocaleDataSource(location: .inMemory)

    _ = awaitValue(locale.update(id: "old", entity: .sample(id: "old", isFavorite: true)))
    _ = awaitValue(locale.update(id: "new", entity: .sample(id: "new", isFavorite: true)))

    XCTAssertEqual(awaitValue(locale.list(request: .favorites))?.map(\.id), ["new", "old"])
  }

  func testSecondInstanceOnTheSameFileReadsTheData() throws {
    let url = try makeStoreURL()
    let first = RestaurantLocaleDataSource(location: .file(url))
    _ = awaitValue(first.add(entities: [.sample(id: "a", sortIndex: 0)]))
    _ = awaitValue(first.update(id: "a", entity: .sample(id: "a", isFavorite: true)))

    let second = RestaurantLocaleDataSource(location: .file(url))

    XCTAssertEqual(awaitValue(second.list(request: .all))?.map(\.id), ["a"])
    XCTAssertEqual(awaitValue(second.get(id: "a")).flatMap { $0?.isFavorite }, true)
  }

  func testUnopenableStoreFailsWithoutCrashing() throws {
    let blocker = try makeStoreURL().deletingLastPathComponent().appendingPathComponent("blocker")
    try Data("x".utf8).write(to: blocker)
    let locale = RestaurantLocaleDataSource(location: .file(blocker.appendingPathComponent("inner.sqlite")))

    XCTAssertEqual(awaitError(locale.list(request: .all)) as? DatabaseError, .unavailable)
    XCTAssertEqual(awaitError(locale.list(request: .favorites)) as? DatabaseError, .unavailable)
    XCTAssertEqual(awaitError(locale.add(entities: [])) as? DatabaseError, .unavailable)
    XCTAssertEqual(awaitError(locale.get(id: "a")) as? DatabaseError, .unavailable)
    XCTAssertEqual(awaitError(locale.update(id: "a", entity: .sample())) as? DatabaseError, .unavailable)
  }

  private func makeStoreURL() throws -> URL {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    directory = folder
    return folder.appendingPathComponent("test.sqlite")
  }
}
