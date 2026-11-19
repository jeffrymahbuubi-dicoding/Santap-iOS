import Common
import Foundation

public enum DatabaseError: LocalizedError, Equatable {
  case unavailable
  case operationFailed
  case missingValue(String)

  public var errorDescription: String? {
    switch self {
    case .unavailable:
      return "error_database_unavailable".localized()
    case .operationFailed:
      return "error_database_operation_failed".localized()
    case .missingValue(let key):
      return "error_database_missing_value".localized(key)
    }
  }
}
