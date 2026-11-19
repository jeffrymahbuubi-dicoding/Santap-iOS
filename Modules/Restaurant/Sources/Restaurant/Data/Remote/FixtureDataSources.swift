#if DEBUG
import Combine
import Foundation
import SantapCore

public struct FixtureRestaurantsDataSource: DataSource {
  private let responder: FixtureResponder

  public init(scenario: FixtureScenario, delay: TimeInterval = 3) {
    responder = FixtureResponder(scenario: scenario, delay: delay)
  }

  public func execute(request: Void) -> AnyPublisher<[RestaurantResponse], Error> {
    let isEmpty = responder.scenario == .empty
    return responder.respond { isEmpty ? [] : FixtureData.restaurants }
  }
}

public struct FixtureSearchDataSource: DataSource {
  private let responder: FixtureResponder

  public init(scenario: FixtureScenario, delay: TimeInterval = 3) {
    responder = FixtureResponder(scenario: scenario, delay: delay)
  }

  public func execute(request: String) -> AnyPublisher<[RestaurantResponse], Error> {
    let isEmpty = responder.scenario == .empty
    return responder.respond { isEmpty ? [] : FixtureData.matching(request) }
  }
}

public struct FixtureDetailDataSource: DataSource {
  private let responder: FixtureResponder

  public init(scenario: FixtureScenario, delay: TimeInterval = 3) {
    responder = FixtureResponder(scenario: scenario, delay: delay)
  }

  public func execute(request: String) -> AnyPublisher<RestaurantDetailResponse, Error> {
    responder.respond {
      guard let restaurant = FixtureData.restaurants.first(where: { $0.id == request }) else {
        throw NetworkError.notFound
      }
      return FixtureData.detail(of: restaurant)
    }
  }
}
#endif
