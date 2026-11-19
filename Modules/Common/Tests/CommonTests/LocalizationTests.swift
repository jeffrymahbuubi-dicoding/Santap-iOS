import XCTest
@testable import Common

final class LocalizationTests: XCTestCase {
  private func table(_ language: String) throws -> [String: String] {
    let url = try XCTUnwrap(
      Bundle.common.url(forResource: "Localizable", withExtension: "strings", subdirectory: nil, localization: language)
    )
    let dictionary = try XCTUnwrap(NSDictionary(contentsOf: url) as? [String: String])
    return dictionary
  }

  private func languageBundle(_ language: String) throws -> Bundle {
    let path = try XCTUnwrap(Bundle.common.path(forResource: language, ofType: "lproj"))
    return try XCTUnwrap(Bundle(path: path))
  }

  private func specifiers(in text: String) throws -> [String] {
    let expression = try NSRegularExpression(pattern: "%(\\d+\\$)?(lld|ld|@|d|f)")
    let range = NSRange(text.startIndex..., in: text)
    return expression.matches(in: text, range: range).compactMap { match in
      Range(match.range, in: text).map { String(text[$0]) }
    }
  }

  func testBothLanguagesHaveTheSameKeys() throws {
    let indonesian = try table("id")
    let english = try table("en")
    XCTAssertFalse(indonesian.isEmpty)
    XCTAssertEqual(Set(indonesian.keys), Set(english.keys))
  }

  func testBothLanguagesUseTheSameFormatSpecifiers() throws {
    let indonesian = try table("id")
    let english = try table("en")
    for (key, value) in indonesian {
      let other = try XCTUnwrap(english[key])
      XCTAssertEqual(try specifiers(in: value), try specifiers(in: other), key)
    }
  }

  func testNoValueIsEmpty() throws {
    for language in ["id", "en"] {
      for (key, value) in try table(language) {
        XCTAssertFalse(value.trimmingCharacters(in: .whitespaces).isEmpty, "\(language) \(key)")
      }
    }
  }

  func testKeysFollowAreaNaming() throws {
    let areas = ["common", "tab", "home", "detail", "favorite", "about", "error"]
    for key in try table("id").keys {
      let area = try XCTUnwrap(key.split(separator: "_").first.map(String.init))
      XCTAssertTrue(areas.contains(area), key)
    }
  }

  func testKeyResolvesPerLanguage() throws {
    XCTAssertEqual("common_retry".localized(in: try languageBundle("id")), "Coba Lagi")
    XCTAssertEqual("common_retry".localized(in: try languageBundle("en")), "Try Again")
    XCTAssertEqual("home_filter_all".localized(in: try languageBundle("id")), "Semua kota")
    XCTAssertEqual("home_filter_all".localized(in: try languageBundle("en")), "All cities")
    XCTAssertEqual("about_error".localized(in: try languageBundle("en")), "The profile could not be loaded")
  }

  func testArgumentIsFilledPerLanguage() throws {
    let indonesian = try languageBundle("id")
    let english = try languageBundle("en")
    XCTAssertEqual("home_filter_active".localized(in: indonesian, arguments: ["Bandung"]), "Kota: Bandung")
    XCTAssertEqual("home_filter_active".localized(in: english, arguments: ["Bandung"]), "City: Bandung")
    XCTAssertEqual(
      "error_network_server".localized(in: english, arguments: [503]),
      "The server could not process the request (code 503)."
    )
  }

  func testUnknownKeyReturnsTheKey() throws {
    XCTAssertEqual("unknown_key_value".localized(in: try languageBundle("id")), "unknown_key_value")
    XCTAssertEqual("unknown_key_value".localized(), "unknown_key_value")
  }

  func testPublicHelperFillsAnArgument() {
    let text = "common_rating".localized("4,5")
    XCTAssertTrue(text.hasSuffix("4,5"))
    XCTAssertTrue(text.hasPrefix("Rating"))
  }

  func testPublicHelperReturnsAKnownLanguageValue() {
    XCTAssertTrue(["Coba Lagi", "Try Again"].contains("common_retry".localized()))
  }
}
