import SantapCore
import XCTest
@testable import Restaurant

final class RestaurantMapperTests: XCTestCase {
  private let mapper = RestaurantMapper()

  func testResponsesBecomeEntitiesWithImageIdAndOrder() throws {
    let list = try JSONFixture.decode(RestaurantListResponse.self, from: "list")

    let entities = mapper.mapResponsesToEntities(list.restaurants ?? [])

    XCTAssertEqual(entities.map(\.id), ["a1", "a2", "a3"])
    XCTAssertEqual(entities.map(\.sortIndex), [0, 1, 2])
    XCTAssertEqual(entities[0].pictureId, "14")
    XCTAssertEqual(entities[0].summary, "Lorem ipsum dolor sit amet.")
    XCTAssertFalse(entities[0].isFavorite)
    XCTAssertNil(entities[0].favoritedAt)
  }

  func testMissingFieldsBecomeDefaults() {
    let response = RestaurantResponse(id: "x", name: "Nama", description: nil, pictureId: nil, city: nil, rating: nil)

    let entity = mapper.mapResponsesToEntities([response])[0]

    XCTAssertEqual(entity.city, "")
    XCTAssertEqual(entity.summary, "")
    XCTAssertEqual(entity.rating, 0)
    XCTAssertNil(entity.pictureId)
  }

  func testRowsWithoutNameAreDroppedAndIndexesStayContiguous() {
    let responses = [
      RestaurantResponse.sample(id: "a"),
      RestaurantResponse(id: "b", name: nil, description: nil, pictureId: nil, city: nil, rating: nil),
      RestaurantResponse.sample(id: "c", name: "   "),
      RestaurantResponse.sample(id: "d")
    ]

    let entities = mapper.mapResponsesToEntities(responses)

    XCTAssertEqual(entities.map(\.id), ["a", "d"])
    XCTAssertEqual(entities.map(\.sortIndex), [0, 1])
  }

  func testEmptyPictureIdBecomesNil() {
    let response = RestaurantResponse(id: "x", name: "Nama", description: nil, pictureId: " ", city: nil, rating: nil)

    XCTAssertNil(mapper.mapResponsesToEntities([response])[0].pictureId)
  }

  func testSingleResponseBecomesEntityAtIndexZero() {
    let entity = mapper.mapResponseToEntity(.sample(id: "one"))

    XCTAssertEqual(entity.id, "one")
    XCTAssertEqual(entity.name, "Warung one")
    XCTAssertEqual(entity.pictureId, "p-one")
    XCTAssertEqual(entity.sortIndex, 0)
    XCTAssertFalse(entity.isFavorite)
  }

  func testEntitiesBecomeDomainsWithImageURL() {
    let models = mapper.mapEntitiesToDomains([.sample(id: "r1")])

    XCTAssertEqual(models.first?.id, "r1")
    XCTAssertEqual(models.first?.name, "Warung r1")
    XCTAssertEqual(models.first?.summary, "Masakan rumahan r1")
    XCTAssertEqual(models.first?.imageURL?.absoluteString, "https://restaurant-api.dicoding.dev/images/medium/p-r1")
  }

  func testSingleEntityBecomesDomain() {
    let model = mapper.mapEntityToDomain(.sample(id: "r2"))

    XCTAssertEqual(model.id, "r2")
    XCTAssertEqual(model.city, "Medan")
    XCTAssertEqual(model.rating, 4.3)
  }

  func testEntityWithoutPictureHasNoImageURL() {
    let entity = RestaurantEntity(
      id: "r", name: "Nama", city: "", summary: "", rating: 0,
      pictureId: nil, sortIndex: 0, isFavorite: false, favoritedAt: nil
    )

    XCTAssertNil(mapper.mapEntitiesToDomains([entity])[0].imageURL)
  }

  func testResponsesBecomeDomainsDirectly() throws {
    let search = try JSONFixture.decode(RestaurantSearchResponse.self, from: "search")

    let models = mapper.mapResponsesToDomains(search.restaurants ?? [])

    XCTAssertEqual(models.map(\.name), ["Kafe Kita"])
    XCTAssertEqual(models.first?.imageURL?.lastPathComponent, "25")
  }

  func testDetailResponseBecomesDomain() throws {
    let envelope = try JSONFixture.decode(RestaurantDetailEnvelope.self, from: "detail")

    let detail = try XCTUnwrap(mapper.mapDetailResponseToDomain(try XCTUnwrap(envelope.restaurant)))

    XCTAssertEqual(detail.name, "Melting Pot")
    XCTAssertEqual(detail.address, "Jln. Pandeglang no 19")
    XCTAssertEqual(detail.categories, ["Italia", "Modern"])
    XCTAssertEqual(detail.foods, ["Paket rosemary", "Toastie salmon"])
    XCTAssertEqual(detail.drinks, ["Es krim", "Sirup"])
    XCTAssertEqual(detail.reviews.count, 1)
    XCTAssertEqual(detail.reviews.first?.name, "Ahmad")
    XCTAssertEqual(detail.reviews.first?.date, "13 November 2019")
    XCTAssertEqual(detail.imageURL?.lastPathComponent, "14")
  }

  func testSparseDetailKeepsOnlyUsableText() throws {
    let envelope = try JSONFixture.decode(RestaurantDetailEnvelope.self, from: "detail-sparse")

    let detail = try XCTUnwrap(mapper.mapDetailResponseToDomain(try XCTUnwrap(envelope.restaurant)))

    XCTAssertEqual(detail.address, "")
    XCTAssertEqual(detail.categories, [])
    XCTAssertEqual(detail.foods, ["Roti"])
    XCTAssertEqual(detail.drinks, [])
    XCTAssertEqual(detail.reviews, [ReviewModel(name: "Dewi", review: "", date: "")])
    XCTAssertNil(detail.imageURL)
  }

  func testDetailWithoutNameMapsToNil() {
    let response = RestaurantDetailResponse(
      id: "x", name: nil, description: nil, city: nil, address: nil,
      pictureId: nil, rating: nil, categories: nil, menus: nil, customerReviews: nil
    )

    XCTAssertNil(mapper.mapDetailResponseToDomain(response))
  }

  func testDomainBecomesEntityKeepingPictureIdAndNotListed() throws {
    let url = try XCTUnwrap(URL(string: "https://restaurant-api.dicoding.dev/images/medium/abc"))
    let model = RestaurantModel(id: "r1", name: "N", city: "C", summary: "S", rating: 3.5, imageURL: url)

    let entity = mapper.mapDomainToEntity(model)

    XCTAssertEqual(entity.id, "r1")
    XCTAssertEqual(entity.summary, "S")
    XCTAssertEqual(entity.pictureId, "abc")
    XCTAssertEqual(entity.sortIndex, -1)
    XCTAssertFalse(entity.isFavorite)
  }

  func testDomainWithoutImageBecomesEntityWithoutPictureId() {
    let model = RestaurantModel(id: "r", name: "N", city: "C", summary: "S", rating: 1, imageURL: nil)

    XCTAssertNil(mapper.mapDomainToEntity(model).pictureId)
  }

  func testMapperWorksThroughTheCoreProtocol() {
    func domain<M: Mapper>(_ mapper: M, _ response: M.Response) -> M.Domain {
      mapper.mapEntityToDomain(mapper.mapResponseToEntity(response))
    }

    let model: RestaurantModel = domain(mapper, .sample(id: "core"))

    XCTAssertEqual(model.id, "core")
  }
}
