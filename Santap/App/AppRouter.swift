import Detail
import Restaurant

final class AppRouter {
  private let makeDetailPresenter: (RestaurantModel) -> DetailPresenter

  init(makeDetailPresenter: @escaping (RestaurantModel) -> DetailPresenter) {
    self.makeDetailPresenter = makeDetailPresenter
  }

  func makeDetailView(for restaurant: RestaurantModel) -> DetailView {
    DetailView(presenter: makeDetailPresenter(restaurant))
  }
}
