import Restaurant
import SantapCore
import SwiftUI
import XCTest
@testable import Favorite

@MainActor
final class FavoritePresenterTests: XCTestCase {
  private var favorites: StubUseCase<Void, [RestaurantModel]>!
  private var update: StubUseCase<FavoriteUpdate, Bool>!
  private var list: [RestaurantModel] = []
  private var removeFails = false

  override func setUp() {
    super.setUp()
    list = []
    removeFails = false
    favorites = StubUseCase(handler: { [unowned self] _ in .success(list) })
    update = StubUseCase(handler: { [unowned self] request in
      removeFails ? .failure(TestError.failed) : .success(request.isFavorite)
    })
  }

  private func makePresenter() -> FavoritePresenter {
    FavoritePresenter(favoritesUseCase: favorites, updateFavoriteUseCase: update)
  }

  func testLoadMovesFromLoadingToLoaded() {
    list = [.sample(id: "a")]
    let presenter = makePresenter()
    XCTAssertEqual(presenter.state, .idle)

    presenter.load()
    XCTAssertEqual(presenter.state, .loading)
    spin(until: { presenter.state == .loaded })

    XCTAssertEqual(presenter.restaurants.map(\.id), ["a"])
  }

  func testLoadWithNoFavoritesIsEmpty() {
    let presenter = makePresenter()

    presenter.load()
    spin(until: { presenter.state == .empty })

    XCTAssertEqual(presenter.state, .empty)
    XCTAssertTrue(presenter.restaurants.isEmpty)
  }

  func testLoadFailureShowsTheMessage() {
    favorites = StubUseCase(result: .failure(TestError.failed))
    let presenter = makePresenter()

    presenter.load()
    spin(until: { presenter.state != .loading })

    XCTAssertEqual(presenter.state, .failed(TestError.failed.localizedDescription))
  }

  func testLoadAgainPicksUpChangesInTheStoredOrder() {
    list = [.sample(id: "a")]
    let presenter = makePresenter()
    presenter.load()
    spin(until: { presenter.state == .loaded })

    list = [.sample(id: "b"), .sample(id: "a")]
    presenter.load()
    spin(until: { presenter.restaurants.count == 2 })

    XCTAssertEqual(presenter.restaurants.map(\.id), ["b", "a"])
  }

  func testRemoveDropsTheRowAndEndsEmpty() {
    let first = RestaurantModel.sample(id: "a")
    list = [first]
    let presenter = makePresenter()
    presenter.load()
    spin(until: { presenter.state == .loaded })

    presenter.remove(first)
    spin(until: { presenter.state == .empty })

    XCTAssertEqual(presenter.state, .empty)
    XCTAssertEqual(update.requests.map(\.restaurant), [first])
    XCTAssertEqual(update.requests.map(\.isFavorite), [false])
  }

  func testRemoveKeepsTheOtherRowsLoaded() {
    list = [.sample(id: "a"), .sample(id: "b")]
    let presenter = makePresenter()
    presenter.load()
    spin(until: { presenter.state == .loaded })

    presenter.remove(.sample(id: "a"))
    spin(until: { presenter.restaurants.count == 1 })

    XCTAssertEqual(presenter.restaurants.map(\.id), ["b"])
    XCTAssertEqual(presenter.state, .loaded)
  }

  func testRemoveFailureKeepsTheRowAndSetsAlert() {
    let first = RestaurantModel.sample(id: "a")
    list = [first]
    removeFails = true
    let presenter = makePresenter()
    presenter.load()
    spin(until: { presenter.state == .loaded })

    presenter.remove(first)
    spin(until: { presenter.alertMessage != nil })

    XCTAssertEqual(presenter.restaurants, [first])
    XCTAssertEqual(presenter.state, .loaded)
    XCTAssertEqual(presenter.alertMessage, TestError.failed.localizedDescription)
  }

  func testRemovedRestaurantLeavesTheRealStoreList() {
    let store = RestaurantLocaleDataSource(location: .inMemory)
    let mapper = RestaurantMapper()
    let updateUseCase = Interactor(repository: UpdateFavoriteRepository(locale: store, mapper: mapper))
    let listUseCase = Interactor(repository: GetFavoritesRepository(locale: store, mapper: mapper))
    let kept = RestaurantModel.sample(id: "kept")
    let turnOn = FavoriteUpdate(restaurant: kept, isFavorite: true)
    XCTAssertEqual(awaitValue(updateUseCase.execute(request: turnOn)), true)
    let presenter = FavoritePresenter(favoritesUseCase: listUseCase, updateFavoriteUseCase: updateUseCase)
    presenter.load()
    spin(until: { presenter.state == .loaded })

    presenter.remove(kept)
    spin(until: { presenter.state == .empty })
    presenter.load()
    spin(until: { presenter.state == .empty })

    XCTAssertTrue(presenter.restaurants.isEmpty)
  }
}

#if canImport(UIKit)
@MainActor
final class FavoriteViewTests: XCTestCase {
  func testViewRendersForEveryState() {
    let loaded = makePresenter(result: .success([.sample(id: "a")]))
    loaded.load()
    spin(until: { loaded.state == .loaded })
    let empty = makePresenter(result: .success([]))
    empty.load()
    spin(until: { empty.state == .empty })
    let failing = makePresenter(result: .failure(TestError.failed))
    failing.load()
    spin(until: { failing.state != .loading })
    let idle = makePresenter(result: .success([]))

    for presenter in [idle, loaded, empty, failing] {
      let host = UIHostingController(
        rootView: NavigationStack { FavoriteView(presenter: presenter) { _ in Text("detail") } }
      )
      XCTAssertNotNil(host.view)
    }
  }

  private func makePresenter(result: Result<[RestaurantModel], Error>) -> FavoritePresenter {
    FavoritePresenter(
      favoritesUseCase: StubUseCase(result: result),
      updateFavoriteUseCase: StubUseCase(result: .success(false))
    )
  }
}
#endif
