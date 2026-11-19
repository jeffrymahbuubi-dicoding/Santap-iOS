import Restaurant
import XCTest
@testable import Home

@MainActor
final class HomePresenterTests: XCTestCase {
  private var listUseCase = StubUseCase<RestaurantListPolicy, [RestaurantModel]>(.success([]))
  private var searchUseCase = StubUseCase<String, [RestaurantModel]>(.success([]))

  override func setUp() {
    super.setUp()
    listUseCase = StubUseCase(.success([]))
    searchUseCase = StubUseCase(.success([]))
  }

  private func makePresenter(debounce: TimeInterval = 0.05) -> HomePresenter {
    HomePresenter(
      listUseCase: listUseCase,
      searchUseCase: searchUseCase,
      debounce: .milliseconds(Int(debounce * 1000))
    )
  }

  private func loadedPresenter(_ restaurants: [RestaurantModel]) -> HomePresenter {
    listUseCase.result = .success(restaurants)
    let presenter = makePresenter()
    presenter.load()
    spin(until: { presenter.state == .loaded })
    return presenter
  }

  func testLoadMovesFromLoadingToLoaded() {
    listUseCase.result = .success([.sample(id: "a"), .sample(id: "b")])
    let presenter = makePresenter()

    presenter.load()
    XCTAssertEqual(presenter.state, .loading)

    spin(until: { presenter.state == .loaded })
    XCTAssertEqual(presenter.state, .loaded)
    XCTAssertEqual(presenter.restaurants.map(\.id), ["a", "b"])
    XCTAssertEqual(listUseCase.requests, [.cached])
  }

  func testLoadWithNoRestaurantsIsEmpty() {
    let presenter = makePresenter()

    presenter.load()
    spin(until: { presenter.state == .empty })

    XCTAssertEqual(presenter.state, .empty)
    XCTAssertTrue(presenter.restaurants.isEmpty)
    XCTAssertTrue(presenter.cities.isEmpty)
  }

  func testLoadFailureThenRetrySucceeds() {
    listUseCase.result = .failure(TestError.failed)
    let presenter = makePresenter()

    presenter.load()
    spin(until: { presenter.state != .loading })
    XCTAssertEqual(presenter.state, .failed(TestError.failed.localizedDescription))

    listUseCase.result = .success([.sample()])
    presenter.retry()
    XCTAssertEqual(presenter.state, .loading)
    spin(until: { presenter.state == .loaded })

    XCTAssertEqual(presenter.state, .loaded)
    XCTAssertEqual(listUseCase.requests.count, 2)
  }

  func testRefreshReplacesRestaurants() async {
    let presenter = loadedPresenter([.sample(id: "old")])

    listUseCase.result = .success([.sample(id: "new")])
    await presenter.refresh()

    XCTAssertEqual(presenter.restaurants.map(\.id), ["new"])
    XCTAssertEqual(presenter.state, .loaded)
    XCTAssertNil(presenter.refreshErrorMessage)
    XCTAssertEqual(listUseCase.requests, [.cached, .refresh])
  }

  func testRefreshFailureWithRowsKeepsRowsAndSetsMessage() async {
    let presenter = loadedPresenter([.sample(id: "kept")])

    listUseCase.result = .failure(TestError.failed)
    await presenter.refresh()

    XCTAssertEqual(presenter.restaurants.map(\.id), ["kept"])
    XCTAssertEqual(presenter.state, .loaded)
    XCTAssertEqual(presenter.refreshErrorMessage, TestError.failed.localizedDescription)
  }

  func testRefreshFailureWithoutRowsFailsTheScreen() async {
    let presenter = makePresenter()
    listUseCase.result = .failure(TestError.failed)

    await presenter.refresh()

    XCTAssertEqual(presenter.state, .failed(TestError.failed.localizedDescription))
    XCTAssertNil(presenter.refreshErrorMessage)
  }

  func testFastTypingSearchesOnceWithTheFinalText() {
    searchUseCase.result = .success([.sample(id: "hit")])
    let presenter = makePresenter(debounce: 0.1)

    presenter.query = "s"
    presenter.query = "sa"
    presenter.query = "sat"
    spin(until: { presenter.state == .loaded })

    XCTAssertEqual(searchUseCase.requests, ["sat"])
    XCTAssertEqual(presenter.restaurants.map(\.id), ["hit"])
  }

  func testDuplicateTextIsIgnored() {
    searchUseCase.result = .success([.sample()])
    let presenter = makePresenter()

    presenter.query = "sate"
    spin(until: { presenter.state == .loaded })
    presenter.query = "sate "
    spin(for: 0.3)

    XCTAssertEqual(searchUseCase.requests, ["sate"])
  }

  func testSearchWithoutHitsIsEmpty() {
    searchUseCase.result = .success([])
    let presenter = makePresenter()

    presenter.query = "zzz"
    spin(until: { presenter.state == .empty })

    XCTAssertEqual(presenter.state, .empty)
  }

  func testFailedSearchDoesNotEndThePipeline() {
    searchUseCase.result = .failure(TestError.failed)
    let presenter = makePresenter()

    presenter.query = "bakso"
    spin(until: { presenter.state == .failed(TestError.failed.localizedDescription) })
    XCTAssertEqual(presenter.state, .failed(TestError.failed.localizedDescription))

    searchUseCase.result = .success([.sample(id: "mie")])
    presenter.query = "mie"
    spin(until: { presenter.state == .loaded })

    XCTAssertEqual(presenter.state, .loaded)
    XCTAssertEqual(presenter.restaurants.map(\.id), ["mie"])
    XCTAssertEqual(searchUseCase.requests, ["bakso", "mie"])
  }

  func testClearingTheQueryLoadsTheFullList() {
    searchUseCase.result = .success([.sample(id: "hit")])
    listUseCase.result = .success([.sample(id: "a"), .sample(id: "b")])
    let presenter = makePresenter()

    presenter.query = "hit"
    spin(until: { presenter.restaurants.count == 1 })
    presenter.query = ""
    spin(until: { presenter.restaurants.count == 2 })

    XCTAssertEqual(presenter.restaurants.map(\.id), ["a", "b"])
    XCTAssertEqual(listUseCase.requests, [.cached])
  }

  func testCitiesAreDerivedFromTheResult() {
    let presenter = loadedPresenter([
      .sample(id: "a", city: "Medan"),
      .sample(id: "b", city: "Bali"),
      .sample(id: "c", city: "medan")
    ])

    XCTAssertEqual(presenter.cities, ["Bali", "Medan"])
    XCTAssertNil(presenter.selectedCity)
    XCTAssertEqual(presenter.restaurants.map(\.id), ["a", "b", "c"])
  }

  func testSelectingACityFiltersTheList() {
    let presenter = loadedPresenter([
      .sample(id: "a", city: "Medan"),
      .sample(id: "b", city: "Bali"),
      .sample(id: "c", city: "Medan")
    ])

    presenter.selectedCity = "Medan"

    XCTAssertEqual(presenter.restaurants.map(\.id), ["a", "c"])
    XCTAssertEqual(presenter.cities, ["Bali", "Medan"])
    XCTAssertEqual(presenter.state, .loaded)
  }

  func testChoosingAllCitiesAgainShowsEverything() {
    let presenter = loadedPresenter([.sample(id: "a", city: "Medan"), .sample(id: "b", city: "Bali")])
    presenter.selectedCity = "Bali"

    presenter.selectedCity = nil

    XCTAssertEqual(presenter.restaurants.map(\.id), ["a", "b"])
  }

  func testAResultWithoutTheChosenCityResetsTheFilter() {
    searchUseCase.result = .success([.sample(id: "z", city: "Bali")])
    let presenter = loadedPresenter([.sample(id: "a", city: "Medan"), .sample(id: "b", city: "Bali")])
    presenter.selectedCity = "Medan"

    presenter.query = "z"
    spin(until: { presenter.restaurants.map(\.id) == ["z"] })

    XCTAssertNil(presenter.selectedCity)
    XCTAssertEqual(presenter.restaurants.map(\.id), ["z"])
    XCTAssertEqual(presenter.cities, ["Bali"])
  }

  func testASearchResultThatStillHasTheCityKeepsTheFilter() {
    searchUseCase.result = .success([
      .sample(id: "m1", city: "Medan"),
      .sample(id: "b1", city: "Bali")
    ])
    let presenter = loadedPresenter([.sample(id: "a", city: "Medan")])
    presenter.selectedCity = "Medan"

    presenter.query = "kafe"
    spin(until: { presenter.cities.count == 2 })

    XCTAssertEqual(presenter.selectedCity, "Medan")
    XCTAssertEqual(presenter.restaurants.map(\.id), ["m1"])
  }

  func testRefreshKeepsTheFilter() async {
    let presenter = loadedPresenter([.sample(id: "a", city: "Medan"), .sample(id: "b", city: "Bali")])
    presenter.selectedCity = "Medan"

    listUseCase.result = .success([
      .sample(id: "n1", city: "Medan"),
      .sample(id: "n2", city: "Bali"),
      .sample(id: "n3", city: "Medan")
    ])
    await presenter.refresh()

    XCTAssertEqual(presenter.selectedCity, "Medan")
    XCTAssertEqual(presenter.restaurants.map(\.id), ["n1", "n3"])
  }

  func testRefreshWithoutTheChosenCityResetsTheFilter() async {
    let presenter = loadedPresenter([.sample(id: "a", city: "Medan"), .sample(id: "b", city: "Bali")])
    presenter.selectedCity = "Medan"

    listUseCase.result = .success([.sample(id: "n", city: "Bali")])
    await presenter.refresh()

    XCTAssertNil(presenter.selectedCity)
    XCTAssertEqual(presenter.restaurants.map(\.id), ["n"])
  }
}
