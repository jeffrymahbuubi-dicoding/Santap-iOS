import Restaurant
import XCTest
@testable import Santap

final class AppConfigurationTests: XCTestCase {
  func testNoArgumentsUseLiveRemoteAndStandardStore() {
    let configuration = AppConfiguration(arguments: [])

    XCTAssertEqual(configuration.remote, .live)
    XCTAssertFalse(configuration.resetStore)
    XCTAssertFalse(configuration.forceDark)
    guard case .standard = configuration.store else {
      return XCTFail("Store harus standard")
    }
  }

  func testFixturesDefaultToSuccessScenarioAndMemoryStore() {
    let configuration = AppConfiguration(arguments: ["-UITestFixtures"])

    XCTAssertEqual(configuration.remote, .fixture(.success))
    guard case .inMemory = configuration.store else {
      return XCTFail("Store harus in-memory")
    }
  }

  func testScenarioArgumentSelectsTheScenario() {
    let scenarios: [FixtureScenario] = [.success, .failure, .empty, .slow]

    for scenario in scenarios {
      let configuration = AppConfiguration(
        arguments: ["-UITestFixtures", "-UITestScenario", scenario.rawValue]
      )
      XCTAssertEqual(configuration.remote, .fixture(scenario))
    }
  }

  func testUnknownScenarioFallsBackToSuccess() {
    let configuration = AppConfiguration(arguments: ["-UITestFixtures", "-UITestScenario", "tidak-ada"])

    XCTAssertEqual(configuration.remote, .fixture(.success))
  }

  func testDiskStoreUsesTheTemporaryFile() {
    let configuration = AppConfiguration(arguments: ["-UITestFixtures", "-UITestStore", "disk"])

    guard case .file(let url) = configuration.store else {
      return XCTFail("Store harus berupa file")
    }
    XCTAssertEqual(url, AppConfiguration.diskStoreURL)
    XCTAssertFalse(configuration.resetStore)
  }

  func testResetStoreNeedsDiskStore() {
    let withDisk = AppConfiguration(
      arguments: ["-UITestFixtures", "-UITestStore", "disk", "-UITestResetStore"]
    )
    let withMemory = AppConfiguration(arguments: ["-UITestFixtures", "-UITestResetStore"])

    XCTAssertTrue(withDisk.resetStore)
    XCTAssertFalse(withMemory.resetStore)
  }

  func testDarkArgumentForcesDarkAppearance() {
    XCTAssertTrue(AppConfiguration(arguments: ["-UITestDark"]).forceDark)
  }

  func testFixtureArgumentsWithoutFlagStayLive() {
    let configuration = AppConfiguration(arguments: ["-UITestScenario", "failure"])

    XCTAssertEqual(configuration.remote, .live)
  }
}
