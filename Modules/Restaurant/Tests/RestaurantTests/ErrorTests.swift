import Alamofire
import Common
import XCTest
@testable import Restaurant

final class ErrorTests: XCTestCase {
  func testNetworkDescriptionsComeFromTheCommonStrings() {
    XCTAssertEqual(NetworkError.noConnection.errorDescription, "error_network_no_connection".localized())
    XCTAssertEqual(NetworkError.notFound.errorDescription, "error_network_not_found".localized())
    XCTAssertEqual(NetworkError.invalidData.errorDescription, "error_network_invalid_data".localized())
    XCTAssertEqual(NetworkError.server(503).errorDescription, "error_network_server".localized(503))
    XCTAssertTrue(NetworkError.server(503).errorDescription?.contains("503") == true)
  }

  func testDatabaseDescriptionsComeFromTheCommonStrings() {
    XCTAssertEqual(DatabaseError.unavailable.errorDescription, "error_database_unavailable".localized())
    XCTAssertEqual(DatabaseError.operationFailed.errorDescription, "error_database_operation_failed".localized())
    XCTAssertEqual(
      DatabaseError.missingValue("ProfileName").errorDescription,
      "error_database_missing_value".localized("ProfileName")
    )
    XCTAssertTrue(DatabaseError.missingValue("ProfileName").errorDescription?.contains("ProfileName") == true)
  }

  func testNoDescriptionIsTheKeyItself() {
    let descriptions = [
      NetworkError.noConnection, .notFound, .invalidData
    ].compactMap(\.errorDescription) + [
      DatabaseError.unavailable, .operationFailed
    ].compactMap(\.errorDescription)

    XCTAssertEqual(descriptions.count, 5)
    XCTAssertTrue(descriptions.allSatisfy { !$0.hasPrefix("error_") })
  }

  func testAlamofireErrorsAreClassified() {
    let notFound = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 404))
    let badGateway = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 502))
    let noData = AFError.responseValidationFailed(reason: .dataFileNil)

    XCTAssertEqual(NetworkError.from(notFound), .notFound)
    XCTAssertEqual(NetworkError.from(badGateway), .server(502))
    XCTAssertEqual(NetworkError.from(noData), .invalidData)
    XCTAssertEqual(NetworkError.from(.explicitlyCancelled), .noConnection)
  }
}
