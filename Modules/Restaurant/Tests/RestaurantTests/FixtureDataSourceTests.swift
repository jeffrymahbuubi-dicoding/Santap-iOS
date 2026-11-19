#if DEBUG
import XCTest
@testable import Restaurant

final class FixtureDataSourceTests: XCTestCase {
  func testSuccessReturnsRestaurantsWithoutPictures() {
    let source = FixtureRestaurantsDataSource(scenario: .success)

    let restaurants = awaitValue(source.execute(request: ()))

    XCTAssertEqual(restaurants?.count, 6)
    XCTAssertTrue(restaurants?.allSatisfy { $0.pictureId == nil } == true)
  }

  func testSearchFiltersByNameIgnoringCase() {
    let source = FixtureSearchDataSource(scenario: .success)

    XCTAssertEqual(awaitValue(source.execute(request: "KAFE"))?.count, 2)
    XCTAssertEqual(awaitValue(source.execute(request: "zzzz"))?.count, 0)
  }

  func testDetailForAKnownIdHasMenuAndReviews() {
    let source = FixtureDetailDataSource(scenario: .success)

    let detail = awaitValue(source.execute(request: "fx1"))

    XCTAssertEqual(detail?.id, "fx1")
    XCTAssertEqual(detail?.menus?.foods?.isEmpty, false)
    XCTAssertEqual(detail?.customerReviews?.isEmpty, false)
    XCTAssertNil(detail?.pictureId)
  }

  func testDetailForAnUnknownIdIsNotFound() {
    let source = FixtureDetailDataSource(scenario: .success)

    XCTAssertEqual(awaitError(source.execute(request: "nope")) as? NetworkError, .notFound)
  }

  func testFailureFailsEveryCall() {
    XCTAssertEqual(
      awaitError(FixtureRestaurantsDataSource(scenario: .failure).execute(request: ())) as? NetworkError,
      .noConnection
    )
    XCTAssertEqual(
      awaitError(FixtureSearchDataSource(scenario: .failure).execute(request: "a")) as? NetworkError,
      .noConnection
    )
    XCTAssertEqual(
      awaitError(FixtureDetailDataSource(scenario: .failure).execute(request: "fx1")) as? NetworkError,
      .noConnection
    )
  }

  func testEmptyReturnsNoRestaurants() {
    XCTAssertEqual(awaitValue(FixtureRestaurantsDataSource(scenario: .empty).execute(request: ()))?.count, 0)
    XCTAssertEqual(awaitValue(FixtureSearchDataSource(scenario: .empty).execute(request: "kafe"))?.count, 0)
  }

  func testSlowAnswersOnlyAfterTheDelay() {
    let source = FixtureRestaurantsDataSource(scenario: .slow, delay: 0.3)
    let started = Date()

    let restaurants = awaitValue(source.execute(request: ()))

    XCTAssertEqual(restaurants?.count, 6)
    XCTAssertGreaterThanOrEqual(Date().timeIntervalSince(started), 0.3)
  }

  func testScenarioNamesParse() {
    XCTAssertEqual(FixtureScenario(rawValue: "slow"), .slow)
    XCTAssertNil(FixtureScenario(rawValue: "other"))
  }
}
#endif
