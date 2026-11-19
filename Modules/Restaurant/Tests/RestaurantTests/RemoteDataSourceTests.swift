import Alamofire
import XCTest
@testable import Restaurant

final class RemoteDataSourceTests: XCTestCase {
  private var session = Session(configuration: StubURLProtocol.configuration)

  override func setUp() {
    super.setUp()
    StubURLProtocol.reset()
    session = Session(configuration: StubURLProtocol.configuration)
  }

  override func tearDown() {
    StubURLProtocol.reset()
    super.tearDown()
  }

  func testListIsRequestedFromTheListEndpointAndDecoded() throws {
    StubURLProtocol.reply = .response(status: 200, body: try JSONFixture.data("list"))

    let restaurants = awaitValue(GetRestaurantsRemoteDataSource(session: session).execute(request: ()))

    XCTAssertEqual(restaurants?.map(\.id), ["a1", "a2", "a3"])
    XCTAssertEqual(StubURLProtocol.requests.first?.url?.absoluteString, "https://restaurant-api.dicoding.dev/list")
  }

  func testSearchSendsTheQueryAsAParameter() throws {
    StubURLProtocol.reply = .response(status: 200, body: try JSONFixture.data("search"))

    let restaurants = awaitValue(SearchRestaurantsRemoteDataSource(session: session).execute(request: "kafe kita"))

    XCTAssertEqual(restaurants?.map(\.id), ["s1"])
    let url = try XCTUnwrap(StubURLProtocol.requests.first?.url)
    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    XCTAssertEqual(components?.path, "/search")
    XCTAssertEqual(components?.queryItems?.first?.name, "q")
    XCTAssertEqual(components?.queryItems?.first?.value, "kafe kita")
  }

  func testSearchWithoutRestaurantsIsEmpty() {
    StubURLProtocol.reply = .response(status: 200, body: Data("{}".utf8))

    XCTAssertEqual(awaitValue(SearchRestaurantsRemoteDataSource(session: session).execute(request: "x"))?.count, 0)
  }

  func testDetailUsesTheIdInThePath() throws {
    StubURLProtocol.reply = .response(status: 200, body: try JSONFixture.data("detail"))

    let detail = awaitValue(GetRestaurantDetailRemoteDataSource(session: session).execute(request: "a1"))

    XCTAssertEqual(detail?.name, "Melting Pot")
    XCTAssertEqual(StubURLProtocol.requests.first?.url?.path, "/detail/a1")
  }

  func testDetailWithoutARestaurantIsNotFound() throws {
    StubURLProtocol.reply = .response(status: 200, body: try JSONFixture.data("not-found"))

    let error = awaitError(GetRestaurantDetailRemoteDataSource(session: session).execute(request: "x"))

    XCTAssertEqual(error as? NetworkError, .notFound)
  }

  func testStatus404IsNotFound() throws {
    StubURLProtocol.reply = .response(status: 404, body: try JSONFixture.data("not-found"))

    let error = awaitError(GetRestaurantDetailRemoteDataSource(session: session).execute(request: "x"))

    XCTAssertEqual(error as? NetworkError, .notFound)
  }

  func testStatus500IsAServerError() {
    StubURLProtocol.reply = .response(status: 500, body: Data())

    let error = awaitError(GetRestaurantsRemoteDataSource(session: session).execute(request: ()))

    XCTAssertEqual(error as? NetworkError, .server(500))
  }

  func testBrokenJSONIsInvalidData() {
    StubURLProtocol.reply = .response(status: 200, body: Data("not json".utf8))

    let error = awaitError(GetRestaurantsRemoteDataSource(session: session).execute(request: ()))

    XCTAssertEqual(error as? NetworkError, .invalidData)
  }

  func testNoConnectionIsReported() {
    StubURLProtocol.reply = .failure(.notConnectedToInternet)

    let error = awaitError(GetRestaurantsRemoteDataSource(session: session).execute(request: ()))

    XCTAssertEqual(error as? NetworkError, .noConnection)
  }

  func testNothingIsRequestedUntilSomeoneSubscribes() {
    _ = GetRestaurantsRemoteDataSource(session: session).execute(request: ())
    _ = SearchRestaurantsRemoteDataSource(session: session).execute(request: "x")
    _ = GetRestaurantDetailRemoteDataSource(session: session).execute(request: "x")

    XCTAssertTrue(StubURLProtocol.requests.isEmpty)
  }
}
