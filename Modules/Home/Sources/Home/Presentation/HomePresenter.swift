import Combine
import Foundation
import Restaurant
import SantapCore

public final class HomePresenter: ObservableObject {
  private typealias Outcome = Result<[RestaurantModel], Error>

  @Published public var query = ""
  @Published public var selectedCity: String?
  @Published public var refreshErrorMessage: String?
  @Published public private(set) var restaurants: [RestaurantModel] = []
  @Published public private(set) var cities: [String] = []
  @Published public private(set) var state: ViewState = .idle

  private let listUseCase: any UseCase<RestaurantListPolicy, [RestaurantModel]>
  private let searchUseCase: any UseCase<String, [RestaurantModel]>
  private let requests = PassthroughSubject<String, Never>()
  private var latest: [RestaurantModel] = []
  private var cancellables = Set<AnyCancellable>()

  public init(
    listUseCase: any UseCase<RestaurantListPolicy, [RestaurantModel]>,
    searchUseCase: any UseCase<String, [RestaurantModel]>,
    debounce: RunLoop.SchedulerTimeType.Stride = .milliseconds(500)
  ) {
    self.listUseCase = listUseCase
    self.searchUseCase = searchUseCase
    bindSearch(debounce: debounce)
    bindFilter()
  }

  public func load() {
    if restaurants.isEmpty {
      state = .loading
    }
    requests.send(trimmedQuery)
  }

  public func retry() {
    state = .loading
    requests.send(trimmedQuery)
  }

  @MainActor
  public func refresh() async {
    do {
      var fresh: [RestaurantModel]?
      for try await list in listUseCase.execute(request: .refresh).values {
        fresh = list
      }
      guard let fresh else {
        return
      }
      if trimmedQuery.isEmpty {
        apply(.success(fresh))
      } else {
        requests.send(trimmedQuery)
      }
    } catch {
      guard !Task.isCancelled else {
        return
      }
      if restaurants.isEmpty {
        state = .failed(error.localizedDescription)
      } else {
        refreshErrorMessage = error.localizedDescription
      }
    }
  }

  private var trimmedQuery: String {
    query.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func bindFilter() {
    $selectedCity
      .dropFirst()
      .removeDuplicates()
      .sink { [weak self] city in
        guard let self else {
          return
        }
        self.restaurants = CityFilter.apply(city: city, to: self.latest)
      }
      .store(in: &cancellables)
  }

  private func bindSearch(debounce: RunLoop.SchedulerTimeType.Stride) {
    let typed = $query
      .dropFirst()
      .debounce(for: debounce, scheduler: RunLoop.main)
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .removeDuplicates()
      .handleEvents(receiveOutput: { [weak self] _ in self?.state = .loading })

    typed
      .merge(with: requests)
      .map { [weak self] keyword -> AnyPublisher<Outcome, Never> in
        self?.outcome(for: keyword) ?? Empty().eraseToAnyPublisher()
      }
      .switchToLatest()
      .receive(on: RunLoop.main)
      .sink { [weak self] outcome in self?.apply(outcome) }
      .store(in: &cancellables)
  }

  private func outcome(for keyword: String) -> AnyPublisher<Outcome, Never> {
    let source = keyword.isEmpty
      ? listUseCase.execute(request: .cached)
      : searchUseCase.execute(request: keyword)
    return source
      .map { Outcome.success($0) }
      .catch { Just(Outcome.failure($0)) }
      .eraseToAnyPublisher()
  }

  private func apply(_ outcome: Outcome) {
    switch outcome {
    case .success(let list):
      latest = list
      cities = CityFilter.cities(in: list)
      if let city = selectedCity, CityFilter.apply(city: city, to: list).isEmpty {
        selectedCity = nil
      }
      restaurants = CityFilter.apply(city: selectedCity, to: list)
      state = list.isEmpty ? .empty : .loaded
    case .failure(let error):
      state = .failed(error.localizedDescription)
    }
  }
}
