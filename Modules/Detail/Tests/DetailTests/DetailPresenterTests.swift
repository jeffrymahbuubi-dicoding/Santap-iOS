import Restaurant
import SantapCore
import SwiftUI
import XCTest
@testable import Detail

@MainActor
final class DetailPresenterTests: XCTestCase {
  private var detail: StubUseCase<String, RestaurantDetailModel>!
  private var favoriteState: StubUseCase<String, Bool>!
  private var update: StubUseCase<FavoriteUpdate, Bool>!
  private var detailFails = false

  override func setUp() {
    super.setUp()
    detailFails = false
    detail = StubUseCase(handler: { [unowned self] _ in
      detailFails ? .failure(TestError.failed) : .success(.sample)
    })
    favoriteState = StubUseCase(result: .success(false))
    update = StubUseCase(handler: { .success($0.isFavorite) })
  }

  private func makePresenter(restaurant: RestaurantModel = .sample()) -> DetailPresenter {
    DetailPresenter(
      restaurant: restaurant,
      detailUseCase: detail,
      favoriteStateUseCase: favoriteState,
      updateFavoriteUseCase: update
    )
  }

  func testExposesTheSelectedRestaurantAtOnce() {
    let restaurant = RestaurantModel.sample(id: "pick")
    let presenter = makePresenter(restaurant: restaurant)

    XCTAssertEqual(presenter.restaurant, restaurant)
    XCTAssertEqual(presenter.state, .idle)
    XCTAssertNil(presenter.detail)
  }

  func testLoadMovesFromLoadingToLoadedWithFavoriteState() {
    favoriteState = StubUseCase(result: .success(true))
    let presenter = makePresenter(restaurant: .sample(id: "pick"))

    presenter.load()
    XCTAssertEqual(presenter.state, .loading)
    spin(until: { presenter.state == .loaded && presenter.isFavorite })

    XCTAssertEqual(presenter.state, .loaded)
    XCTAssertEqual(presenter.detail, .sample)
    XCTAssertTrue(presenter.isFavorite)
    XCTAssertEqual(detail.requests, ["pick"])
    XCTAssertEqual(favoriteState.requests, ["pick"])
  }

  func testLoadFailureShowsTheMessageAndRetryRecovers() {
    detailFails = true
    let presenter = makePresenter()

    presenter.load()
    spin(until: { presenter.state != .loading })
    XCTAssertEqual(presenter.state, .failed(TestError.failed.localizedDescription))

    detailFails = false
    presenter.load()
    spin(until: { presenter.state == .loaded })

    XCTAssertEqual(presenter.state, .loaded)
    XCTAssertEqual(detail.requests.count, 2)
  }

  func testLoadingAgainKeepsTheDetailOnScreen() {
    let presenter = makePresenter()
    presenter.load()
    spin(until: { presenter.state == .loaded })

    presenter.load()

    XCTAssertEqual(presenter.state, .loaded)
    spin(until: { self.detail.requests.count == 2 })
    XCTAssertEqual(detail.requests.count, 2)
  }

  func testFavoriteStateFailureLeavesTheHeartEmpty() {
    favoriteState = StubUseCase(result: .failure(TestError.failed))
    let presenter = makePresenter()

    presenter.load()
    spin(until: { presenter.state == .loaded })
    RunLoop.main.run(until: Date().addingTimeInterval(0.05))

    XCTAssertFalse(presenter.isFavorite)
    XCTAssertNil(presenter.alertMessage)
  }

  func testToggleFavoriteSavesTheOppositeState() {
    let restaurant = RestaurantModel.sample(id: "pick")
    let presenter = makePresenter(restaurant: restaurant)

    presenter.toggleFavorite()
    spin(until: { presenter.isFavorite })
    XCTAssertTrue(presenter.isFavorite)

    presenter.toggleFavorite()
    spin(until: { !presenter.isFavorite })
    XCTAssertFalse(presenter.isFavorite)
    XCTAssertEqual(update.requests.map(\.isFavorite), [true, false])
    XCTAssertEqual(update.requests.map(\.restaurant), [restaurant, restaurant])
  }

  func testToggleFavoriteFailureKeepsStateAndSetsAlert() {
    update = StubUseCase(result: .failure(TestError.failed))
    let presenter = makePresenter()

    presenter.toggleFavorite()
    spin(until: { presenter.alertMessage != nil })

    XCTAssertFalse(presenter.isFavorite)
    XCTAssertEqual(presenter.alertMessage, TestError.failed.localizedDescription)
  }

  func testTheRealStoreKeepsTheFavoriteBetweenTwoPresenters() {
    let store = RestaurantLocaleDataSource(location: .inMemory)
    let restaurant = RestaurantModel.sample(id: "kept")
    let updateUseCase = Interactor(repository: UpdateFavoriteRepository(locale: store, mapper: RestaurantMapper()))
    let stateUseCase = Interactor(repository: GetFavoriteStateRepository(locale: store))
    let first = DetailPresenter(
      restaurant: restaurant,
      detailUseCase: detail,
      favoriteStateUseCase: stateUseCase,
      updateFavoriteUseCase: updateUseCase
    )

    first.toggleFavorite()
    spin(until: { first.isFavorite })
    let second = DetailPresenter(
      restaurant: restaurant,
      detailUseCase: detail,
      favoriteStateUseCase: stateUseCase,
      updateFavoriteUseCase: updateUseCase
    )
    second.load()
    spin(until: { second.isFavorite })

    XCTAssertTrue(second.isFavorite)
  }
}

#if canImport(UIKit)
@MainActor
final class DetailViewTests: XCTestCase {
  func testViewRendersForEveryState() {
    let loaded = makePresenter(detail: .success(.sample))
    loaded.load()
    spin(until: { loaded.state == .loaded })
    let failing = makePresenter(detail: .failure(TestError.failed))
    failing.load()
    spin(until: { failing.state != .loading })
    let idle = makePresenter(detail: .success(.sample))

    for presenter in [idle, failing, loaded] {
      let host = UIHostingController(rootView: NavigationStack { DetailView(presenter: presenter) })
      XCTAssertNotNil(host.view)
    }
  }

  private func makePresenter(detail: Result<RestaurantDetailModel, Error>) -> DetailPresenter {
    DetailPresenter(
      restaurant: .sample(),
      detailUseCase: StubUseCase(result: detail),
      favoriteStateUseCase: StubUseCase(result: .success(true)),
      updateFavoriteUseCase: StubUseCase(result: .success(true))
    )
  }
}
#endif
