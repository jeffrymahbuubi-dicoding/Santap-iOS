import Common
import Restaurant
import SantapCore
import SwiftUI

public struct HomeView<Destination: View>: View {
  @ObservedObject private var presenter: HomePresenter
  private let destination: (RestaurantModel) -> Destination

  public init(presenter: HomePresenter, destination: @escaping (RestaurantModel) -> Destination) {
    self.presenter = presenter
    self.destination = destination
  }

  public var body: some View {
    content
      .navigationTitle("home_title".localized())
      .searchable(text: $presenter.query, prompt: "home_search_prompt".localized())
      .toolbar {
        if !presenter.cities.isEmpty {
          ToolbarItem(placement: .navigationBarTrailing) {
            filterMenu
          }
        }
      }
      .alert("home_refresh_error_title".localized(), isPresented: $presenter.refreshErrorMessage.isPresent) {
        Button("common_ok".localized(), role: .cancel) {}
      } message: {
        Text(presenter.refreshErrorMessage ?? "")
      }
      .onAppear {
        if presenter.state == .idle {
          presenter.load()
        }
      }
  }

  private var filterMenu: some View {
    Menu {
      Picker("home_filter_button".localized(), selection: $presenter.selectedCity) {
        Text("home_filter_all".localized()).tag(String?.none)
        ForEach(presenter.cities, id: \.self) { city in
          Text(city).tag(String?.some(city))
        }
      }
    } label: {
      Image(systemName: filterIconName)
    }
    .accessibilityLabel("home_filter_button".localized())
    .accessibilityIdentifier("home.filterButton")
  }

  private var filterIconName: String {
    presenter.selectedCity == nil
      ? "line.3.horizontal.decrease.circle"
      : "line.3.horizontal.decrease.circle.fill"
  }

  @ViewBuilder
  private var content: some View {
    switch presenter.state {
    case .idle, .loading:
      LoadingStateView(message: "home_loading".localized(), identifier: "home.loading")
    case .failed(let message):
      ErrorStateView(
        message: message,
        identifier: "home.error",
        retryIdentifier: "home.retry",
        onRetry: presenter.retry
      )
    case .empty:
      EmptyStateView(
        systemImage: "magnifyingglass",
        title: emptyTitle,
        subtitle: nil,
        identifier: "home.empty"
      )
    case .loaded:
      VStack(spacing: 0) {
        if let city = presenter.selectedCity {
          activeFilter(city)
        }
        list
      }
    }
  }

  private var emptyTitle: String {
    let keyword = presenter.query.trimmingCharacters(in: .whitespacesAndNewlines)
    return keyword.isEmpty ? "home_empty".localized() : "home_empty_search".localized(keyword)
  }

  private func activeFilter(_ city: String) -> some View {
    Text("home_filter_active".localized(city))
      .font(.subheadline.weight(.semibold))
      .foregroundStyle(.secondary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 16)
      .padding(.vertical, 8)
      .accessibilityIdentifier("home.filter.active")
  }

  private var list: some View {
    List(presenter.restaurants) { restaurant in
      NavigationLink {
        destination(restaurant)
      } label: {
        RestaurantRow(restaurant: restaurant)
      }
      .accessibilityIdentifier("restaurant.row.\(restaurant.id)")
    }
    .listStyle(.plain)
    .readableWidth()
    .refreshable {
      await presenter.refresh()
    }
    .accessibilityIdentifier("home.list")
  }
}
