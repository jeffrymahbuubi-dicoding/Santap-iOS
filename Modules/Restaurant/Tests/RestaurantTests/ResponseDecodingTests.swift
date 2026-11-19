import XCTest
@testable import Restaurant

final class ResponseDecodingTests: XCTestCase {
  func testListDecodesAllFieldsAndToleratesNullAndMissing() throws {
    let list = try JSONFixture.decode(RestaurantListResponse.self, from: "list")

    let restaurants = try XCTUnwrap(list.restaurants)
    XCTAssertEqual(list.count, 3)
    XCTAssertEqual(restaurants.count, 3)
    XCTAssertEqual(restaurants[0].id, "a1")
    XCTAssertEqual(restaurants[0].pictureId, "14")
    XCTAssertEqual(restaurants[0].rating, 4.2)
    XCTAssertNil(restaurants[1].pictureId)
    XCTAssertEqual(restaurants[1].rating, 4)
    XCTAssertEqual(restaurants[2].id, "a3")
    XCTAssertNil(restaurants[2].city)
    XCTAssertNil(restaurants[2].rating)
  }

  func testSearchDecodes() throws {
    let search = try JSONFixture.decode(RestaurantSearchResponse.self, from: "search")

    XCTAssertEqual(search.founded, 1)
    XCTAssertEqual(search.restaurants?.first?.name, "Kafe Kita")
  }

  func testDetailDecodesMenusCategoriesAndReviews() throws {
    let envelope = try JSONFixture.decode(RestaurantDetailEnvelope.self, from: "detail")

    let detail = try XCTUnwrap(envelope.restaurant)
    XCTAssertEqual(detail.address, "Jln. Pandeglang no 19")
    XCTAssertEqual(detail.categories?.compactMap(\.name), ["Italia", "Modern"])
    XCTAssertEqual(detail.menus?.foods?.count, 2)
    XCTAssertEqual(detail.menus?.drinks?.compactMap(\.name), ["Es krim", "Sirup"])
    XCTAssertEqual(detail.customerReviews?.first?.name, "Ahmad")
    XCTAssertEqual(detail.customerReviews?.first?.date, "13 November 2019")
  }

  func testDetailWithNullAndMissingFieldsStillDecodes() throws {
    let envelope = try JSONFixture.decode(RestaurantDetailEnvelope.self, from: "detail-sparse")

    let detail = try XCTUnwrap(envelope.restaurant)
    XCTAssertEqual(detail.id, "a9")
    XCTAssertNil(detail.address)
    XCTAssertNil(detail.categories)
    XCTAssertNil(detail.menus?.drinks)
    XCTAssertNil(detail.menus?.foods?.first?.name)
    XCTAssertNil(detail.customerReviews?.first?.review)
  }

  func testErrorBodyDecodesWithoutRestaurant() throws {
    let envelope = try JSONFixture.decode(RestaurantDetailEnvelope.self, from: "not-found")

    XCTAssertEqual(envelope.error, true)
    XCTAssertNil(envelope.restaurant)
  }

  func testListWithoutRestaurantsKeyDecodes() throws {
    let list = try JSONDecoder().decode(RestaurantListResponse.self, from: Data("{}".utf8))

    XCTAssertNil(list.restaurants)
  }
}
