import About
import Common
import Favorite
import Home
import SwiftUI

struct RootView: View {
  let homePresenter: HomePresenter
  let favoritePresenter: FavoritePresenter
  let aboutPresenter: AboutPresenter
  let router: AppRouter

  init(
    homePresenter: HomePresenter,
    favoritePresenter: FavoritePresenter,
    aboutPresenter: AboutPresenter,
    router: AppRouter
  ) {
    self.homePresenter = homePresenter
    self.favoritePresenter = favoritePresenter
    self.aboutPresenter = aboutPresenter
    self.router = router
  }

  var body: some View {
    TabView {
      NavigationStack {
        HomeView(presenter: homePresenter, destination: router.makeDetailView)
      }
      .tabItem { Label("tab_home".localized(), systemImage: "fork.knife") }

      NavigationStack {
        FavoriteView(presenter: favoritePresenter, destination: router.makeDetailView)
      }
      .tabItem { Label("tab_favorite".localized(), systemImage: "heart") }

      NavigationStack {
        AboutView(presenter: aboutPresenter)
      }
      .tabItem { Label("tab_about".localized(), systemImage: "person.crop.circle") }
    }
  }
}
