import Common
import Restaurant
import SwiftUI

public struct FavoriteView<Destination: View>: View {
  @ObservedObject private var presenter: FavoritePresenter
  private let destination: (RestaurantModel) -> Destination

  public init(presenter: FavoritePresenter, destination: @escaping (RestaurantModel) -> Destination) {
    self.presenter = presenter
    self.destination = destination
  }

  public var body: some View {
    content
      .navigationTitle("favorite_title".localized())
      .alert("favorite_save_error_title".localized(), isPresented: $presenter.alertMessage.isPresent) {
        Button("common_ok".localized(), role: .cancel) {}
      } message: {
        Text(presenter.alertMessage ?? "")
      }
      .onAppear {
        presenter.load()
      }
  }

  @ViewBuilder
  private var content: some View {
    switch presenter.state {
    case .idle, .loading:
      LoadingStateView(message: "favorite_loading".localized(), identifier: "favorite.loading")
    case .failed(let message):
      ErrorStateView(
        message: message,
        identifier: "favorite.error",
        retryIdentifier: "favorite.retry",
        onRetry: presenter.load
      )
    case .empty:
      EmptyStateView(
        systemImage: "heart.slash",
        title: "favorite_empty_title".localized(),
        subtitle: "favorite_empty_subtitle".localized(),
        identifier: "favorite.empty"
      )
    case .loaded:
      list
    }
  }

  private var list: some View {
    List(presenter.restaurants) { restaurant in
      NavigationLink {
        destination(restaurant)
      } label: {
        RestaurantRow(restaurant: restaurant)
      }
      .accessibilityIdentifier("restaurant.row.\(restaurant.id)")
      .swipeActions(edge: .trailing, allowsFullSwipe: true) {
        Button(role: .destructive) {
          presenter.remove(restaurant)
        } label: {
          Text("favorite_delete".localized())
        }
      }
    }
    .listStyle(.plain)
    .readableWidth()
    .accessibilityIdentifier("favorite.list")
  }
}
