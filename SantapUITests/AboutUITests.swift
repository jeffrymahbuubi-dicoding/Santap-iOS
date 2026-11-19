import XCTest

final class AboutUITests: FixtureUITestCase {
  func testAboutShowsNameAndPhoto() {
    launchApp()

    openTab("Tentang")

    XCTAssertFalse(waitFor(element("about.name")).label.isEmpty)
    waitFor(element("about.photo"))
    XCTAssertTrue(app.staticTexts["Tentang Aplikasi"].exists)
    XCTAssertTrue(app.staticTexts["Sumber data: Dicoding Restaurant API"].exists)
    attachScreenshot(named: "11-tentang")
  }
}
