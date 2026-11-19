import About
import Detail
import Favorite
import Foundation
import Home
import Restaurant
import SantapCore
import Swinject

final class Injection {
  private typealias LocaleSource = any LocaleDataSource<RestaurantListRequest, RestaurantEntity>
  private typealias ListSource = any DataSource<Void, [RestaurantResponse]>
  private typealias SearchSource = any DataSource<String, [RestaurantResponse]>
  private typealias DetailSource = any DataSource<String, RestaurantDetailResponse>
  private typealias ProfileSource = any DataSource<Void, ProfileEntity>
  private typealias ListRepository = any Repository<RestaurantListPolicy, [RestaurantModel]>
  private typealias SearchRepository = any Repository<String, [RestaurantModel]>
  private typealias DetailRepository = any Repository<String, RestaurantDetailModel>
  private typealias FavoriteStateRepository = any Repository<String, Bool>
  private typealias UpdateRepository = any Repository<FavoriteUpdate, Bool>
  private typealias FavoritesRepository = any Repository<Void, [RestaurantModel]>
  private typealias ProfileRepository = any Repository<Void, ProfileModel>
  private typealias ListUseCase = any UseCase<RestaurantListPolicy, [RestaurantModel]>
  private typealias SearchUseCase = any UseCase<String, [RestaurantModel]>
  private typealias DetailUseCase = any UseCase<String, RestaurantDetailModel>
  private typealias FavoriteStateUseCase = any UseCase<String, Bool>
  private typealias UpdateUseCase = any UseCase<FavoriteUpdate, Bool>
  private typealias FavoritesUseCase = any UseCase<Void, [RestaurantModel]>
  private typealias ProfileUseCase = any UseCase<Void, ProfileModel>

  private let configuration: AppConfiguration
  private let container = Container()

  init(configuration: AppConfiguration = .current) {
    self.configuration = configuration
    if configuration.resetStore {
      Self.removeStoreFiles()
    }
    registerDataSources()
    registerRepositories()
    registerUseCases()
    registerPresenters()
  }

  func provideHomePresenter() -> HomePresenter {
    container.require(HomePresenter.self)
  }

  func provideFavoritePresenter() -> FavoritePresenter {
    container.require(FavoritePresenter.self)
  }

  func provideAboutPresenter() -> AboutPresenter {
    container.require(AboutPresenter.self)
  }

  func provideDetailPresenter(for restaurant: RestaurantModel) -> DetailPresenter {
    container.require(DetailPresenter.self, argument: restaurant)
  }

  private func registerDataSources() {
    let configuration = self.configuration
    container.register(LocaleSource.self) { _ in
      RestaurantLocaleDataSource(location: configuration.store)
    }
    .inObjectScope(.container)
    container.register(ListSource.self) { _ in
      Self.makeListSource(for: configuration.remote)
    }
    .inObjectScope(.container)
    container.register(SearchSource.self) { _ in
      Self.makeSearchSource(for: configuration.remote)
    }
    .inObjectScope(.container)
    container.register(DetailSource.self) { _ in
      Self.makeDetailSource(for: configuration.remote)
    }
    .inObjectScope(.container)
    container.register(ProfileSource.self) { _ in
      ProfileDataSource()
    }
    .inObjectScope(.container)
    container.register(RestaurantMapper.self) { _ in
      RestaurantMapper()
    }
    .inObjectScope(.container)
  }

  private func registerRepositories() {
    container.register(ListRepository.self) { resolver in
      GetRestaurantsRepository(
        locale: resolver.require(LocaleSource.self),
        remote: resolver.require(ListSource.self),
        mapper: resolver.require(RestaurantMapper.self)
      )
    }
    .inObjectScope(.container)
    container.register(SearchRepository.self) { resolver in
      SearchRestaurantsRepository(
        remote: resolver.require(SearchSource.self),
        mapper: resolver.require(RestaurantMapper.self)
      )
    }
    .inObjectScope(.container)
    container.register(DetailRepository.self) { resolver in
      GetRestaurantDetailRepository(
        remote: resolver.require(DetailSource.self),
        mapper: resolver.require(RestaurantMapper.self)
      )
    }
    .inObjectScope(.container)
    container.register(FavoriteStateRepository.self) { resolver in
      GetFavoriteStateRepository(locale: resolver.require(LocaleSource.self))
    }
    .inObjectScope(.container)
    container.register(UpdateRepository.self) { resolver in
      UpdateFavoriteRepository(
        locale: resolver.require(LocaleSource.self),
        mapper: resolver.require(RestaurantMapper.self)
      )
    }
    .inObjectScope(.container)
    container.register(FavoritesRepository.self) { resolver in
      GetFavoritesRepository(
        locale: resolver.require(LocaleSource.self),
        mapper: resolver.require(RestaurantMapper.self)
      )
    }
    .inObjectScope(.container)
    container.register(ProfileRepository.self) { resolver in
      GetProfileRepository(dataSource: resolver.require(ProfileSource.self))
    }
    .inObjectScope(.container)
  }

  private func registerUseCases() {
    container.register(ListUseCase.self) { resolver in
      Interactor(repository: resolver.require(ListRepository.self))
    }
    container.register(SearchUseCase.self) { resolver in
      SearchRestaurantsInteractor(
        search: resolver.require(SearchRepository.self),
        list: resolver.require(ListRepository.self)
      )
    }
    container.register(DetailUseCase.self) { resolver in
      Interactor(repository: resolver.require(DetailRepository.self))
    }
    container.register(FavoriteStateUseCase.self) { resolver in
      Interactor(repository: resolver.require(FavoriteStateRepository.self))
    }
    container.register(UpdateUseCase.self) { resolver in
      Interactor(repository: resolver.require(UpdateRepository.self))
    }
    container.register(FavoritesUseCase.self) { resolver in
      Interactor(repository: resolver.require(FavoritesRepository.self))
    }
    container.register(ProfileUseCase.self) { resolver in
      Interactor(repository: resolver.require(ProfileRepository.self))
    }
  }

  private func registerPresenters() {
    container.register(HomePresenter.self) { resolver in
      HomePresenter(
        listUseCase: resolver.require(ListUseCase.self),
        searchUseCase: resolver.require(SearchUseCase.self)
      )
    }
    container.register(FavoritePresenter.self) { resolver in
      FavoritePresenter(
        favoritesUseCase: resolver.require(FavoritesUseCase.self),
        updateFavoriteUseCase: resolver.require(UpdateUseCase.self)
      )
    }
    container.register(AboutPresenter.self) { resolver in
      AboutPresenter(useCase: resolver.require(ProfileUseCase.self))
    }
    container.register(DetailPresenter.self) { (resolver, restaurant: RestaurantModel) in
      DetailPresenter(
        restaurant: restaurant,
        detailUseCase: resolver.require(DetailUseCase.self),
        favoriteStateUseCase: resolver.require(FavoriteStateUseCase.self),
        updateFavoriteUseCase: resolver.require(UpdateUseCase.self)
      )
    }
  }

  private static func makeListSource(for remote: AppConfiguration.Remote) -> ListSource {
    #if DEBUG
    if case .fixture(let scenario) = remote {
      return FixtureRestaurantsDataSource(scenario: scenario)
    }
    #endif
    return GetRestaurantsRemoteDataSource()
  }

  private static func makeSearchSource(for remote: AppConfiguration.Remote) -> SearchSource {
    #if DEBUG
    if case .fixture(let scenario) = remote {
      return FixtureSearchDataSource(scenario: scenario)
    }
    #endif
    return SearchRestaurantsRemoteDataSource()
  }

  private static func makeDetailSource(for remote: AppConfiguration.Remote) -> DetailSource {
    #if DEBUG
    if case .fixture(let scenario) = remote {
      return FixtureDetailDataSource(scenario: scenario)
    }
    #endif
    return GetRestaurantDetailRemoteDataSource()
  }

  private static func removeStoreFiles() {
    let base = AppConfiguration.diskStoreURL.path
    for suffix in ["", "-wal", "-shm"] {
      try? FileManager.default.removeItem(atPath: base + suffix)
    }
  }
}

private extension Resolver {
  func require<Service>(_ type: Service.Type) -> Service {
    guard let service = resolve(type) else {
      preconditionFailure("Registrasi tidak ditemukan: \(type)")
    }
    return service
  }

  func require<Service, Argument>(_ type: Service.Type, argument: Argument) -> Service {
    guard let service = resolve(type, argument: argument) else {
      preconditionFailure("Registrasi tidak ditemukan: \(type)")
    }
    return service
  }
}
