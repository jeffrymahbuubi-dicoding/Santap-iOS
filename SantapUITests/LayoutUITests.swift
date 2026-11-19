import XCTest

final class LayoutUITests: FixtureUITestCase {
  func testListIsReadableInLandscape() {
    launchApp(orientation: .landscapeLeft)

    XCTAssertTrue(waitFor(row("fx1")).isHittable)
    XCTAssertTrue(app.tabBars.buttons["Favorit"].isHittable)
    attachScreenshot(named: "12-beranda-lanskap")
  }

  func testDetailIsReadableInLandscape() {
    launchApp(orientation: .landscapeLeft)

    openDetail(of: "fx1")

    XCTAssertTrue(waitFor(favoriteButton()).isHittable)
    attachScreenshot(named: "13-detail-lanskap")
  }

  func testFavoritesAreReadableInLandscape() {
    launchApp(orientation: .landscapeLeft)
    addToFavorites("fx1")
    goBack()
    openTab("Favorit")

    XCTAssertTrue(waitFor(row("fx1")).isHittable)
  }

  func testListInDarkAppearance() {
    launchApp(dark: true)

    XCTAssertTrue(waitFor(row("fx1")).isHittable)
    attachScreenshot(named: "14-beranda-gelap")
  }

  func testDetailInDarkAppearance() {
    launchApp(dark: true)

    openDetail(of: "fx1")

    XCTAssertTrue(waitFor(favoriteButton()).isHittable)
    attachScreenshot(named: "15-detail-gelap")
  }
}
