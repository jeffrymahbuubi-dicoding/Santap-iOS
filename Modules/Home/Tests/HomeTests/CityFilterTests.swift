import Restaurant
import XCTest
@testable import Home

final class CityFilterTests: XCTestCase {
  private func list(_ cities: String...) -> [RestaurantModel] {
    cities.enumerated().map { index, city in .sample(id: "r\(index)", city: city) }
  }

  func testCitiesOfAnEmptyListIsEmpty() {
    XCTAssertEqual(CityFilter.cities(in: []), [])
  }

  func testCitiesAreUnique() {
    XCTAssertEqual(CityFilter.cities(in: list("Medan", "Bandung", "Medan")), ["Bandung", "Medan"])
  }

  func testCitiesDifferingOnlyInCaseCountOnce() {
    XCTAssertEqual(CityFilter.cities(in: list("Medan", "medan", "MEDAN")), ["Medan"])
  }

  func testBlankCitiesAreLeftOut() {
    XCTAssertEqual(CityFilter.cities(in: list("", "  ", "\n", "Bali")), ["Bali"])
  }

  func testCitiesAreSortedIgnoringCase() {
    XCTAssertEqual(
      CityFilter.cities(in: list("surabaya", "Bali", "malang", "Aceh")),
      ["Aceh", "Bali", "malang", "surabaya"]
    )
  }

  func testCitiesAreTrimmed() {
    XCTAssertEqual(CityFilter.cities(in: list(" Medan ", "Medan")), ["Medan"])
  }

  func testNilCityKeepsEveryRestaurant() {
    let restaurants = list("Medan", "Bali", "")

    XCTAssertEqual(CityFilter.apply(city: nil, to: restaurants), restaurants)
  }

  func testCityKeepsOnlyItsRestaurants() {
    let restaurants = list("Medan", "Bali", "Medan")

    let result = CityFilter.apply(city: "Medan", to: restaurants)

    XCTAssertEqual(result.map(\.id), ["r0", "r2"])
  }

  func testMatchIgnoresCase() {
    let restaurants = list("Medan", "MEDAN", "Bali")

    let result = CityFilter.apply(city: "mEdAn", to: restaurants)

    XCTAssertEqual(result.map(\.id), ["r0", "r1"])
  }

  func testMatchIgnoresSurroundingSpaces() {
    let restaurants = list(" Medan", "Bali")

    XCTAssertEqual(CityFilter.apply(city: "Medan ", to: restaurants).map(\.id), ["r0"])
  }

  func testUnknownCityGivesNothing() {
    XCTAssertEqual(CityFilter.apply(city: "Paris", to: list("Medan")), [])
  }

  func testEmptyListStaysEmpty() {
    XCTAssertEqual(CityFilter.apply(city: "Medan", to: []), [])
    XCTAssertEqual(CityFilter.apply(city: nil, to: []), [])
  }

  func testOrderOfTheInputIsKept() {
    let restaurants = [
      RestaurantModel.sample(id: "z", city: "Medan"),
      RestaurantModel.sample(id: "a", city: "Medan")
    ]

    XCTAssertEqual(CityFilter.apply(city: "Medan", to: restaurants).map(\.id), ["z", "a"])
  }
}
