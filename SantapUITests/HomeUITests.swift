import XCTest

final class HomeUITests: FixtureUITestCase {
  func testListShowsRestaurantRows() {
    launchApp()

    let first = waitFor(row("fx1"))
    XCTAssertTrue(first.label.contains("Kafe Senja"))
    XCTAssertTrue(first.label.contains("Medan"))
    XCTAssertTrue(row("fx6").exists)
    attachScreenshot(named: "01-beranda")
  }

  func testSearchNarrowsTheList() {
    launchApp()
    waitFor(row("fx2"))

    search(for: "kafe")

    XCTAssertTrue(row("fx1").waitForExistence(timeout: timeout))
    XCTAssertTrue(row("fx6").exists)
    XCTAssertTrue(row("fx2").waitForNonExistence(timeout: timeout))
    attachScreenshot(named: "04-pencarian")
  }

  func testSearchWithoutMatchShowsEmptyText() {
    launchApp()
    waitFor(row("fx2"))

    search(for: "zzzxyz")

    waitFor(element("home.empty"))
    XCTAssertTrue(app.staticTexts["Tidak ada restoran untuk “zzzxyz”"].exists)
    attachScreenshot(named: "05-pencarian-kosong")
  }

  func testFailureScenarioShowsErrorAndRetry() {
    launchApp(scenario: .failure)

    waitFor(element("home.error"))
    XCTAssertTrue(waitFor(element("home.retry")).isHittable)
    XCTAssertTrue(app.buttons["Coba Lagi"].exists)
    attachScreenshot(named: "03-beranda-galat")
  }

  func testSlowScenarioShowsLoadingIndicator() {
    launchApp(scenario: .slow)

    waitFor(element("home.loading"))
    XCTAssertTrue(app.staticTexts["Memuat restoran…"].exists)
    attachScreenshot(named: "02-beranda-memuat")
    waitFor(row("fx1"))
  }

  func testEmptyScenarioShowsEmptyState() {
    launchApp(scenario: .empty)

    waitFor(element("home.empty"))
  }

  func testCityFilterNarrowsAndRestoresTheList() {
    launchApp()
    waitFor(row("fx2"))

    waitFor(element("home.filterButton")).tap()
    attachScreenshot(named: "16-filter-menu")
    waitFor(app.buttons["Medan"]).tap()

    XCTAssertTrue(waitFor(element("home.filter.active")).label.contains("Medan"))
    XCTAssertTrue(row("fx1").waitForExistence(timeout: timeout))
    XCTAssertTrue(row("fx2").waitForNonExistence(timeout: timeout))
    attachScreenshot(named: "17-beranda-kota")

    element("home.filterButton").tap()
    waitFor(app.buttons["Semua kota"]).tap()

    XCTAssertTrue(row("fx2").waitForExistence(timeout: timeout))
    XCTAssertTrue(element("home.filter.active").waitForNonExistence(timeout: timeout))
  }

  func testEnglishLanguageShowsEnglishTexts() {
    launchApp(scenario: .failure, language: "en")

    waitFor(element("home.error"))
    XCTAssertTrue(app.buttons["Try Again"].exists)
    XCTAssertTrue(app.tabBars.buttons["Home"].exists)
    XCTAssertTrue(app.tabBars.buttons["Favorites"].exists)
    XCTAssertTrue(app.tabBars.buttons["About"].exists)
    attachScreenshot(named: "18-beranda-inggris")
  }
}
