import XCTest

final class FavoriteUITests: FixtureUITestCase {
  func testEmptyStateWithoutFavorites() {
    launchApp()

    openTab("Favorit")

    waitFor(element("favorite.empty"))
    XCTAssertTrue(app.staticTexts["Belum ada restoran favorit"].exists)
    attachScreenshot(named: "09-favorit-kosong")
  }

  func testSwipeRemovesFavorite() {
    launchApp()
    addToFavorites("fx1")
    goBack()
    openTab("Favorit")

    waitFor(row("fx1")).swipeLeft()
    let remove = waitFor(app.buttons["Hapus"])
    attachScreenshot(named: "10-favorit-geser")
    remove.tap()

    waitFor(element("favorite.empty"))
  }

  func testFavoriteSurvivesRelaunch() {
    launchApp(disk: true, reset: true)
    addToFavorites("fx1")

    relaunchWithoutReset()
    openTab("Favorit")

    XCTAssertTrue(waitFor(row("fx1")).label.contains("Kafe Senja"))
  }
}
