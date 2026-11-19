import Foundation
import Restaurant

struct AppConfiguration {
  enum Remote: Equatable {
    case live
    case fixture(FixtureScenario)
  }

  let remote: Remote
  let store: StoreLocation
  let resetStore: Bool
  let forceDark: Bool

  init(arguments: [String]) {
    #if DEBUG
    let useFixtures = arguments.contains("-UITestFixtures")
    let scenario = Self.value(after: "-UITestScenario", in: arguments)
      .flatMap(FixtureScenario.init(rawValue:)) ?? .success
    let onDisk = Self.value(after: "-UITestStore", in: arguments) == "disk"
    remote = useFixtures ? .fixture(scenario) : .live
    store = Self.storeLocation(useFixtures: useFixtures, onDisk: onDisk)
    resetStore = useFixtures && onDisk && arguments.contains("-UITestResetStore")
    forceDark = arguments.contains("-UITestDark")
    #else
    remote = .live
    store = .standard
    resetStore = false
    forceDark = false
    #endif
  }

  static var current: AppConfiguration {
    var arguments = ProcessInfo.processInfo.arguments
    #if DEBUG
    let isHostedTest = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    if isHostedTest && !arguments.contains("-UITestFixtures") {
      arguments.append("-UITestFixtures")
    }
    #endif
    return AppConfiguration(arguments: arguments)
  }

  static var diskStoreURL: URL {
    FileManager.default.temporaryDirectory.appendingPathComponent("santap-uitest.sqlite")
  }

  #if DEBUG
  private static func value(after flag: String, in arguments: [String]) -> String? {
    guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else {
      return nil
    }
    return arguments[index + 1]
  }

  private static func storeLocation(useFixtures: Bool, onDisk: Bool) -> StoreLocation {
    guard useFixtures else {
      return .standard
    }
    return onDisk ? .file(diskStoreURL) : .inMemory
  }
  #endif
}
