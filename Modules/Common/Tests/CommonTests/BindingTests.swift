import SwiftUI
import XCTest
@testable import Common

final class BindingTests: XCTestCase {
  func testIsPresentFollowsTheValue() {
    var message: String?
    let binding = Binding<String?>(get: { message }, set: { message = $0 })
    XCTAssertFalse(binding.isPresent.wrappedValue)
    message = "gagal"
    XCTAssertTrue(binding.isPresent.wrappedValue)
  }

  func testDismissingClearsTheValue() {
    var message: String? = "gagal"
    let binding = Binding<String?>(get: { message }, set: { message = $0 })
    binding.isPresent.wrappedValue = false
    XCTAssertNil(message)
  }

  func testPresentingDoesNotInventAValue() {
    var message: String?
    let binding = Binding<String?>(get: { message }, set: { message = $0 })
    binding.isPresent.wrappedValue = true
    XCTAssertNil(message)
  }
}
