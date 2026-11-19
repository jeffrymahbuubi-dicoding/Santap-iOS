import XCTest

enum UITestScenario: String {
  case success
  case failure
  case empty
  case slow
}

class FixtureUITestCase: XCTestCase {
  var app = XCUIApplication()
  let timeout: TimeInterval = 15

  override func setUp() {
    super.setUp()
    continueAfterFailure = false
  }

  func launchApp(
    scenario: UITestScenario = .success,
    dark: Bool = false,
    disk: Bool = false,
    reset: Bool = false,
    language: String = "id",
    orientation: UIDeviceOrientation = .portrait
  ) {
    app = XCUIApplication()
    app.launchArguments = ["-UITestFixtures", "-UITestScenario", scenario.rawValue, "-AppleLanguages", "(\(language))"]
    if dark {
      app.launchArguments.append("-UITestDark")
    }
    if disk {
      app.launchArguments += ["-UITestStore", "disk"]
    }
    if reset {
      app.launchArguments.append("-UITestResetStore")
    }
    addTeardownBlock { XCUIDevice.shared.orientation = .portrait }
    app.launch()
    XCUIDevice.shared.orientation = orientation
  }

  func relaunchWithoutReset() {
    app.terminate()
    app = XCUIApplication()
    app.launchArguments = [
      "-UITestFixtures", "-UITestScenario", "success", "-UITestStore", "disk", "-AppleLanguages", "(id)"
    ]
    app.launch()
  }

  func element(_ identifier: String) -> XCUIElement {
    app.descendants(matching: .any).matching(identifier: identifier).firstMatch
  }

  func row(_ id: String) -> XCUIElement {
    element("restaurant.row.\(id)")
  }

  func favoriteButton() -> XCUIElement {
    element("detail.favoriteButton")
  }

  @discardableResult
  func waitFor(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
    let appeared = element.waitForExistence(timeout: timeout)
    XCTAssertTrue(appeared, "Elemen tidak muncul: \(element)", file: file, line: line)
    return element
  }

  func openTab(_ title: String) {
    app.tabBars.buttons[title].tap()
  }

  func openDetail(of id: String) {
    waitFor(row(id)).tap()
    waitFor(app.staticTexts["Ulasan"])
  }

  func addToFavorites(_ id: String) {
    openDetail(of: id)
    let button = waitFor(favoriteButton())
    XCTAssertEqual(button.label, "Tambah ke Favorit")
    button.tap()
    XCTAssertTrue(app.buttons["Hapus dari Favorit"].waitForExistence(timeout: timeout))
  }

  func goBack() {
    app.navigationBars.buttons.element(boundBy: 0).tap()
  }

  func search(for text: String) {
    let field = app.searchFields["Cari restoran"]
    waitFor(field)
    field.tap()
    field.typeText(text)
  }

  func attachScreenshot(named name: String) {
    let attachment = XCTAttachment(image: uprightScreenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  private func uprightScreenshot() -> UIImage {
    let image = XCUIScreen.main.screenshot().image
    let format = UIGraphicsImageRendererFormat()
    format.scale = image.scale
    return UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
      image.draw(at: .zero)
    }
  }
}
