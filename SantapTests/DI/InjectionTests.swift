import Restaurant
import SantapCore
import XCTest
@testable import Santap

final class InjectionTests: XCTestCase {
  private func makeInjection(_ scenario: FixtureScenario = .success) -> Injection {
    Injection(configuration: AppConfiguration(arguments: ["-UITestFixtures", "-UITestScenario", scenario.rawValue]))
  }

  private func waitUntil(_ condition: @escaping () -> Bool, timeout: TimeInterval = 5) {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() && Date() < deadline {
      RunLoop.main.run(until: Date().addingTimeInterval(0.05))
    }
  }

  private func sample(id: String) -> RestaurantModel {
    RestaurantModel(
      id: id,
      name: "Warung \(id)",
      city: "Medan",
      summary: "Masakan rumahan \(id)",
      rating: 4.3,
      imageURL: nil
    )
  }

  func testProvidesAllTabPresenters() {
    let injection = makeInjection()

    XCTAssertEqual(injection.provideHomePresenter().state, .idle)
    XCTAssertEqual(injection.provideFavoritePresenter().state, .idle)
    XCTAssertEqual(injection.provideAboutPresenter().state, .idle)
    XCTAssertNil(injection.provideAboutPresenter().value)
  }

  func testHomePresenterLoadsFixtureRestaurants() {
    let presenter = makeInjection().provideHomePresenter()

    presenter.load()
    waitUntil { presenter.state == .loaded }

    XCTAssertEqual(presenter.state, .loaded)
    XCTAssertEqual(presenter.restaurants.count, 6)
  }

  func testFailureScenarioLeadsToFailedState() {
    let presenter = makeInjection(.failure).provideHomePresenter()

    presenter.load()
    waitUntil {
      if case .failed = presenter.state {
        return true
      }
      return false
    }

    guard case .failed = presenter.state else {
      return XCTFail("State harus failed")
    }
  }

  func testEmptyScenarioLeadsToEmptyState() {
    let presenter = makeInjection(.empty).provideHomePresenter()

    presenter.load()
    waitUntil { presenter.state == .empty }

    XCTAssertEqual(presenter.state, .empty)
  }

  func testCityFilterNarrowsTheLoadedList() {
    let presenter = makeInjection().provideHomePresenter()
    presenter.load()
    waitUntil { presenter.state == .loaded }

    presenter.selectedCity = "Medan"
    waitUntil { presenter.restaurants.count == 1 }

    XCTAssertEqual(presenter.cities.count, 6)
    XCTAssertEqual(presenter.restaurants.map(\.id), ["fx1"])
  }

  func testSearchNarrowsTheListThroughTheFixtureSource() {
    let presenter = makeInjection().provideHomePresenter()
    presenter.load()
    waitUntil { presenter.state == .loaded }

    presenter.query = "kafe"
    waitUntil { presenter.restaurants.count == 2 }

    XCTAssertEqual(Set(presenter.restaurants.map(\.id)), ["fx1", "fx6"])
  }

  func testDetailPresentersAreSeparateAndHoldTheirRestaurant() {
    let injection = makeInjection()
    let first = sample(id: "a")
    let second = sample(id: "b")

    let firstPresenter = injection.provideDetailPresenter(for: first)
    let secondPresenter = injection.provideDetailPresenter(for: second)

    XCTAssertFalse(firstPresenter === secondPresenter)
    XCTAssertEqual(firstPresenter.restaurant, first)
    XCTAssertEqual(secondPresenter.restaurant, second)
  }

  func testDetailPresenterLoadsFixtureDetail() {
    let presenter = makeInjection().provideDetailPresenter(for: sample(id: "fx1"))

    presenter.load()
    waitUntil { presenter.state == .loaded }

    XCTAssertEqual(presenter.detail?.id, "fx1")
    XCTAssertFalse(presenter.isFavorite)
  }

  func testFavoriteSetInDetailAppearsInFavoritePresenter() {
    let injection = makeInjection()
    let detail = injection.provideDetailPresenter(for: sample(id: "fx1"))
    let favorites = injection.provideFavoritePresenter()

    detail.toggleFavorite()
    waitUntil { detail.isFavorite }
    favorites.load()
    waitUntil { favorites.state == .loaded }

    XCTAssertTrue(detail.isFavorite)
    XCTAssertEqual(favorites.restaurants.map(\.id), ["fx1"])
  }

  func testFavoriteStateIsSharedBetweenDetailPresenters() {
    let injection = makeInjection()
    let first = injection.provideDetailPresenter(for: sample(id: "fx1"))
    first.toggleFavorite()
    waitUntil { first.isFavorite }

    let second = injection.provideDetailPresenter(for: sample(id: "fx1"))
    second.load()
    waitUntil { second.state == .loaded && second.isFavorite }

    XCTAssertTrue(second.isFavorite)
  }

  func testAboutPresenterLoadsProfileFromBundle() {
    let presenter = makeInjection().provideAboutPresenter()

    presenter.load(request: ())
    waitUntil { presenter.value != nil }

    XCTAssertEqual(presenter.value?.photoName, "ProfilePhoto")
    XCTAssertFalse(presenter.value?.name.isEmpty ?? true)
  }
}
