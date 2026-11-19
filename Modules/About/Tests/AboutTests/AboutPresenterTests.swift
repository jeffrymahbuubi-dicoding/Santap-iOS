import SantapCore
import SwiftUI
import XCTest
@testable import About

@MainActor
final class AboutPresenterTests: XCTestCase {
  private func makePresenter(_ result: Result<ProfileEntity, Error>) -> AboutPresenter {
    let repository = GetProfileRepository(dataSource: StubProfileDataSource(result: result), photoName: "Foto")
    return AboutPresenter(useCase: Interactor(repository: repository))
  }

  func testLoadPublishesTheProfile() {
    let presenter = makePresenter(.success(ProfileEntity(name: "A", role: "B")))
    XCTAssertNil(presenter.value)
    XCTAssertEqual(presenter.state, .idle)

    presenter.load(request: ())
    spin(until: { presenter.state == .loaded })

    XCTAssertEqual(presenter.value, ProfileModel(name: "A", role: "B", photoName: "Foto"))
  }

  func testFailedLoadShowsTheFailedState() {
    let presenter = makePresenter(.failure(ProfileError.missingValue("ProfileRole")))

    presenter.load(request: ())
    spin(until: { presenter.state != .loading })

    XCTAssertNil(presenter.value)
    XCTAssertEqual(presenter.state, .failed(ProfileError.missingValue("ProfileRole").localizedDescription))
  }

  func testLoadingAgainAfterFailureStartsANewRequest() {
    let presenter = makePresenter(.failure(TestError.failed))
    presenter.load(request: ())
    spin(until: { presenter.state != .loading })

    presenter.load(request: ())

    XCTAssertEqual(presenter.state, .loading)
  }

#if canImport(UIKit)
  func testViewRendersForEveryState() {
    let failing = makePresenter(.failure(TestError.failed))
    failing.load(request: ())
    spin(until: { failing.state != .loading })
    let loaded = makePresenter(.success(ProfileEntity(name: "A", role: "B")))
    loaded.load(request: ())
    spin(until: { loaded.state == .loaded })
    let idle = makePresenter(.failure(TestError.failed))

    for presenter in [idle, failing, loaded] {
      let host = UIHostingController(rootView: NavigationStack { AboutView(presenter: presenter) })
      XCTAssertNotNil(host.view)
    }
  }
#endif
}
