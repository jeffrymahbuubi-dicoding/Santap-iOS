import Combine
import Foundation
import SantapCore

public struct ProfileDataSource: DataSource {
  static let nameKey = "ProfileName"
  static let roleKey = "ProfileRole"

  private let bundle: Bundle

  public init(bundle: Bundle = .main) {
    self.bundle = bundle
  }

  public func execute(request: Void) -> AnyPublisher<ProfileEntity, Error> {
    let bundle = bundle
    return Deferred {
      Future { promise in
        promise(Result {
          ProfileEntity(
            name: try Self.value(for: Self.nameKey, in: bundle),
            role: try Self.value(for: Self.roleKey, in: bundle)
          )
        })
      }
    }
    .eraseToAnyPublisher()
  }

  private static func value(for key: String, in bundle: Bundle) throws -> String {
    let text = (bundle.object(forInfoDictionaryKey: key) as? String)?
      .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    guard !text.isEmpty else {
      throw ProfileError.missingValue(key)
    }
    return text
  }
}
