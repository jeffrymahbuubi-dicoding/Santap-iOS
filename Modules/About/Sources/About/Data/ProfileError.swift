import Common
import Foundation

public enum ProfileError: LocalizedError, Equatable {
  case missingValue(String)

  public var errorDescription: String? {
    "about_error".localized()
  }
}
