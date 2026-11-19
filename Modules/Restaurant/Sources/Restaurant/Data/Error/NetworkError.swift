import Alamofire
import Common
import Foundation

public enum NetworkError: LocalizedError, Equatable {
  case noConnection
  case notFound
  case server(Int)
  case invalidData

  public var errorDescription: String? {
    switch self {
    case .noConnection:
      return "error_network_no_connection".localized()
    case .notFound:
      return "error_network_not_found".localized()
    case .server(let code):
      return "error_network_server".localized(code)
    case .invalidData:
      return "error_network_invalid_data".localized()
    }
  }

  static func from(_ error: AFError) -> NetworkError {
    if let code = error.responseCode {
      return code == 404 ? .notFound : .server(code)
    }
    if error.isResponseSerializationError || error.isResponseValidationError {
      return .invalidData
    }
    return .noConnection
  }
}
