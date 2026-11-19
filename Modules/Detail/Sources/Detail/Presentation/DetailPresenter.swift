import Combine
import Foundation
import Restaurant
import SantapCore

public final class DetailPresenter: ObservableObject {
  public let restaurant: RestaurantModel

  @Published public private(set) var detail: RestaurantDetailModel?
  @Published public private(set) var state: ViewState = .idle
  @Published public private(set) var isFavorite = false
  @Published public var alertMessage: String?

  private let detailUseCase: GetRestaurantDetailUseCase
  private let favoriteStateUseCase: GetFavoriteStateUseCase
  private let updateFavoriteUseCase: UpdateFavoriteUseCase
  private var loadCancellables = Set<AnyCancellable>()
  private var toggleCancellable: AnyCancellable?

  public init(
    restaurant: RestaurantModel,
    detailUseCase: GetRestaurantDetailUseCase,
    favoriteStateUseCase: GetFavoriteStateUseCase,
    updateFavoriteUseCase: UpdateFavoriteUseCase
  ) {
    self.restaurant = restaurant
    self.detailUseCase = detailUseCase
    self.favoriteStateUseCase = favoriteStateUseCase
    self.updateFavoriteUseCase = updateFavoriteUseCase
  }

  public func load() {
    loadCancellables.removeAll()
    if detail == nil {
      state = .loading
    }

    detailUseCase.execute(request: restaurant.id)
      .receive(on: RunLoop.main)
      .sink(
        receiveCompletion: { [weak self] completion in
          if case .failure(let error) = completion {
            self?.state = .failed(error.localizedDescription)
          }
        },
        receiveValue: { [weak self] detail in
          self?.detail = detail
          self?.state = .loaded
        }
      )
      .store(in: &loadCancellables)

    favoriteStateUseCase.execute(request: restaurant.id)
      .replaceError(with: false)
      .receive(on: RunLoop.main)
      .sink { [weak self] favorite in self?.isFavorite = favorite }
      .store(in: &loadCancellables)
  }

  public func toggleFavorite() {
    let update = FavoriteUpdate(restaurant: restaurant, isFavorite: !isFavorite)
    toggleCancellable = updateFavoriteUseCase.execute(request: update)
      .receive(on: RunLoop.main)
      .sink(
        receiveCompletion: { [weak self] completion in
          if case .failure(let error) = completion {
            self?.alertMessage = error.localizedDescription
          }
        },
        receiveValue: { [weak self] favorite in self?.isFavorite = favorite }
      )
  }
}
