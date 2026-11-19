import Combine
import Foundation

public enum FixtureScenario: String {
  case success
  case failure
  case empty
  case slow
}

#if DEBUG
struct FixtureResponder {
  let scenario: FixtureScenario
  let delay: TimeInterval

  func respond<Value>(_ work: @escaping () throws -> Value) -> AnyPublisher<Value, Error> {
    let scenario = self.scenario
    let source = Deferred {
      Future<Value, Error> { promise in
        switch scenario {
        case .failure:
          promise(.failure(NetworkError.noConnection))
        case .success, .empty, .slow:
          promise(Result { try work() })
        }
      }
    }
    if scenario == .slow {
      return source
        .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    return source.eraseToAnyPublisher()
  }
}

enum FixtureData {
  static let restaurants: [RestaurantResponse] = [
    RestaurantResponse(
      id: "fx1", name: "Kafe Senja", description: "Kafe dengan kopi lokal dan kue hangat.",
      pictureId: nil, city: "Medan", rating: 4.6),
    RestaurantResponse(
      id: "fx2", name: "Warung Bu Tini", description: "Masakan rumahan dengan sambal buatan sendiri.",
      pictureId: nil, city: "Bandung", rating: 4.2),
    RestaurantResponse(
      id: "fx3", name: "Kedai Kopi Pagi", description: "Sarapan sederhana dan kopi tubruk.",
      pictureId: nil, city: "Surabaya", rating: 4.0),
    RestaurantResponse(
      id: "fx4", name: "Dapur Nusantara", description: "Hidangan khas dari berbagai daerah.",
      pictureId: nil, city: "Malang", rating: 4.8),
    RestaurantResponse(
      id: "fx5", name: "Rumah Makan Jaya", description: "Nasi dan lauk pauk yang selalu segar.",
      pictureId: nil, city: "Jakarta", rating: 3.9),
    RestaurantResponse(
      id: "fx6", name: "Kafe Lembah", description: "Tempat santai dengan pemandangan sawah.",
      pictureId: nil, city: "Bali", rating: 4.4)
  ]

  static func matching(_ query: String) -> [RestaurantResponse] {
    let keyword = query.lowercased()
    return restaurants.filter { restaurant in
      (restaurant.name ?? "").lowercased().contains(keyword)
        || (restaurant.description ?? "").lowercased().contains(keyword)
    }
  }

  static func detail(of restaurant: RestaurantResponse) -> RestaurantDetailResponse {
    RestaurantDetailResponse(
      id: restaurant.id,
      name: restaurant.name,
      description: restaurant.description,
      city: restaurant.city,
      address: "Jl. Mawar No. 12, \(restaurant.city ?? "")",
      pictureId: nil,
      rating: restaurant.rating,
      categories: [NamedResponse(name: "Indonesia"), NamedResponse(name: "Rumahan")],
      menus: MenusResponse(
        foods: [NamedResponse(name: "Nasi Goreng"), NamedResponse(name: "Soto Ayam")],
        drinks: [NamedResponse(name: "Es Teh"), NamedResponse(name: "Kopi Susu")]
      ),
      customerReviews: [
        ReviewResponse(name: "Sari", review: "Makanannya enak dan pelayanannya ramah.", date: "12 Oktober 2026")
      ]
    )
  }
}
#endif
