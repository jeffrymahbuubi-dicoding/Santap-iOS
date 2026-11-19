import XCTest

final class DetailUITests: FixtureUITestCase {
  func testDetailShowsAddressMenuAndReview() {
    launchApp()

    openDetail(of: "fx1")

    XCTAssertTrue(app.staticTexts["Medan, Jl. Mawar No. 12, Medan"].exists)
    XCTAssertTrue(app.staticTexts["Deskripsi"].exists)
    XCTAssertTrue(app.staticTexts["Menu"].exists)
    XCTAssertTrue(app.staticTexts["Makanan"].exists)
    XCTAssertTrue(app.staticTexts["• Nasi Goreng"].exists)
    XCTAssertTrue(app.staticTexts["Minuman"].exists)
    XCTAssertTrue(app.staticTexts["Ulasan"].exists)
    XCTAssertTrue(app.staticTexts["Makanannya enak dan pelayanannya ramah."].exists)
    attachScreenshot(named: "06-detail")
  }

  func testHeartAddsRestaurantToFavorites() {
    launchApp()

    addToFavorites("fx1")
    attachScreenshot(named: "07-detail-favorit")
    goBack()
    openTab("Favorit")

    let favorite = waitFor(row("fx1"))
    XCTAssertTrue(favorite.label.contains("Kafe Senja"))
    attachScreenshot(named: "08-favorit")
    favorite.tap()
    waitFor(app.staticTexts["Ulasan"])
    XCTAssertEqual(waitFor(favoriteButton()).label, "Hapus dari Favorit")
  }

  func testHeartAgainRemovesFavorite() {
    launchApp()
    addToFavorites("fx1")

    favoriteButton().tap()
    XCTAssertTrue(app.buttons["Tambah ke Favorit"].waitForExistence(timeout: timeout))
    goBack()
    openTab("Favorit")

    waitFor(element("favorite.empty"))
  }
}
