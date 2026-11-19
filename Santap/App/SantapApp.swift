import About
import Favorite
import Home
import SwiftUI

@main
struct SantapApp: App {
  private let homePresenter: HomePresenter
  private let favoritePresenter: FavoritePresenter
  private let aboutPresenter: AboutPresenter
  private let router: AppRouter
  private let forceDark: Bool

  init() {
    let configuration = AppConfiguration.current
    let injection = Injection(configuration: configuration)
    homePresenter = injection.provideHomePresenter()
    favoritePresenter = injection.provideFavoritePresenter()
    aboutPresenter = injection.provideAboutPresenter()
    router = AppRouter(makeDetailPresenter: injection.provideDetailPresenter)
    forceDark = configuration.forceDark
  }

  var body: some Scene {
    WindowGroup {
      RootView(
        homePresenter: homePresenter,
        favoritePresenter: favoritePresenter,
        aboutPresenter: aboutPresenter,
        router: router
      )
      .preferredColorScheme(forceDark ? .dark : nil)
    }
  }
}
