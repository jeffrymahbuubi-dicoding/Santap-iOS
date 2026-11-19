import Combine
import Foundation
import Restaurant
import SantapCore

public final class FavoritePresenter: ObservableObject {
  @Published public private(set) var restaurants: [RestaurantModel] = []
  @Published public private(set) var state: ViewState = .idle
  @Published public var alertMessage: String?

  private let favoritesUseCase: GetFavoritesUseCase
  private let updateFavoriteUseCase: UpdateFavoriteUseCase
  private var loadCancellable: AnyCancellable?
  private var removeCancellables = Set<AnyCancellable>()

  public init(
    favoritesUseCase: GetFavoritesUseCase,
    updateFavoriteUseCase: UpdateFavoriteUseCase
  ) {
    self.favoritesUseCase = favoritesUseCase
    self.updateFavoriteUseCase = updateFavoriteUseCase
  }

  public func load() {
    if state == .idle {
      state = .loading
    }
    loadCancellable = favoritesUseCase.execute(request: ())
      .receive(on: RunLoop.main)
      .sink(
        receiveCompletion: { [weak self] completion in
          if case .failure(let error) = completion {
            self?.state = .failed(error.localizedDescription)
          }
        },
        receiveValue: { [weak self] list in
          self?.restaurants = list
          self?.state = list.isEmpty ? .empty : .loaded
        }
      )
  }

  public func remove(_ restaurant: RestaurantModel) {
    let update = FavoriteUpdate(restaurant: restaurant, isFavorite: false)
    updateFavoriteUseCase.execute(request: update)
      .receive(on: RunLoop.main)
      .sink(
        receiveCompletion: { [weak self] completion in
          if case .failure(let error) = completion {
            self?.alertMessage = error.localizedDescription
          }
        },
        receiveValue: { [weak self] _ in
          guard let self else {
            return
          }
          self.restaurants.removeAll { $0.id == restaurant.id }
          self.state = self.restaurants.isEmpty ? .empty : .loaded
        }
      )
      .store(in: &removeCancellables)
  }
}
