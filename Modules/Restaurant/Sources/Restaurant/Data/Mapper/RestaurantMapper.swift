import Foundation
import SantapCore

public struct RestaurantMapper: Mapper {
  public init() {}

  public func mapResponseToEntity(_ response: RestaurantResponse) -> RestaurantEntity {
    entity(from: response, sortIndex: 0)
  }

  public func mapEntityToDomain(_ entity: RestaurantEntity) -> RestaurantModel {
    RestaurantModel(
      id: entity.id,
      name: entity.name,
      city: entity.city,
      summary: entity.summary,
      rating: entity.rating,
      imageURL: Self.imageURL(pictureId: entity.pictureId)
    )
  }

  public func mapResponsesToEntities(_ responses: [RestaurantResponse]) -> [RestaurantEntity] {
    responses
      .filter { !Self.clean($0.name).isEmpty }
      .enumerated()
      .map { index, response in entity(from: response, sortIndex: index) }
  }

  public func mapEntitiesToDomains(_ entities: [RestaurantEntity]) -> [RestaurantModel] {
    entities.map(mapEntityToDomain)
  }

  public func mapResponsesToDomains(_ responses: [RestaurantResponse]) -> [RestaurantModel] {
    mapEntitiesToDomains(mapResponsesToEntities(responses))
  }

  public func mapDetailResponseToDomain(_ response: RestaurantDetailResponse) -> RestaurantDetailModel? {
    let name = Self.clean(response.name)
    guard !name.isEmpty else {
      return nil
    }
    return RestaurantDetailModel(
      id: response.id,
      name: name,
      city: Self.clean(response.city),
      address: Self.clean(response.address),
      description: Self.clean(response.description),
      rating: response.rating ?? 0,
      imageURL: Self.imageURL(pictureId: response.pictureId),
      categories: Self.names(of: response.categories),
      foods: Self.names(of: response.menus?.foods),
      drinks: Self.names(of: response.menus?.drinks),
      reviews: (response.customerReviews ?? []).map { review in
        ReviewModel(name: Self.clean(review.name), review: Self.clean(review.review), date: Self.clean(review.date))
      }
    )
  }

  public func mapDomainToEntity(_ model: RestaurantModel) -> RestaurantEntity {
    RestaurantEntity(
      id: model.id,
      name: model.name,
      city: model.city,
      summary: model.summary,
      rating: model.rating,
      pictureId: model.imageURL?.lastPathComponent,
      sortIndex: -1,
      isFavorite: false,
      favoritedAt: nil
    )
  }

  private func entity(from response: RestaurantResponse, sortIndex: Int) -> RestaurantEntity {
    let pictureId = Self.clean(response.pictureId)
    return RestaurantEntity(
      id: response.id,
      name: Self.clean(response.name),
      city: Self.clean(response.city),
      summary: Self.clean(response.description),
      rating: response.rating ?? 0,
      pictureId: pictureId.isEmpty ? nil : pictureId,
      sortIndex: sortIndex,
      isFavorite: false,
      favoritedAt: nil
    )
  }

  private static func imageURL(pictureId: String?) -> URL? {
    guard let pictureId, !pictureId.isEmpty else {
      return nil
    }
    return URL(string: Endpoints.image(pictureId: pictureId))
  }

  private static func names(of items: [NamedResponse]?) -> [String] {
    (items ?? []).map { clean($0.name) }.filter { !$0.isEmpty }
  }

  private static func clean(_ text: String?) -> String {
    (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
