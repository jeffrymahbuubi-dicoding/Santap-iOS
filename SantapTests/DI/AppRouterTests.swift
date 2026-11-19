import Detail
import Restaurant
import XCTest
@testable import Santap

final class AppRouterTests: XCTestCase {
  func testRouterAsksTheFactoryForTheGivenRestaurant() {
    let injection = Injection(configuration: AppConfiguration(arguments: ["-UITestFixtures"]))
    var requested: [RestaurantModel] = []
    let router = AppRouter { restaurant in
      requested.append(restaurant)
      return injection.provideDetailPresenter(for: restaurant)
    }
    let restaurant = RestaurantModel(
      id: "z",
      name: "Warung z",
      city: "Medan",
      summary: "Masakan rumahan",
      rating: 4.3,
      imageURL: nil
    )

    _ = router.makeDetailView(for: restaurant)

    XCTAssertEqual(requested, [restaurant])
  }
}
