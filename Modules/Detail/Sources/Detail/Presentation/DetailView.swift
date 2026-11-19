import Common
import Restaurant
import SwiftUI

public struct DetailView: View {
  @StateObject private var presenter: DetailPresenter

  public init(presenter: DetailPresenter) {
    _presenter = StateObject(wrappedValue: presenter)
  }

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        RemoteImageView(url: presenter.detail?.imageURL ?? presenter.restaurant.imageURL)
          .aspectRatio(16 / 9, contentMode: .fit)
          .clipShape(RoundedRectangle(cornerRadius: 12))
        header
        stateContent
      }
      .padding(16)
      .readableWidth()
    }
    .navigationTitle(presenter.restaurant.name)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        favoriteButton
      }
    }
    .alert("detail_save_error_title".localized(), isPresented: $presenter.alertMessage.isPresent) {
      Button("common_ok".localized(), role: .cancel) {}
    } message: {
      Text(presenter.alertMessage ?? "")
    }
    .onAppear {
      if presenter.state == .idle {
        presenter.load()
      }
    }
  }

  private var favoriteButton: some View {
    Button {
      presenter.toggleFavorite()
    } label: {
      Image(systemName: presenter.isFavorite ? "heart.fill" : "heart")
        .frame(minWidth: 44, minHeight: 44)
    }
    .accessibilityLabel(
      presenter.isFavorite ? "detail_favorite_remove".localized() : "detail_favorite_add".localized()
    )
    .accessibilityIdentifier("detail.favoriteButton")
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 8) {
      Label(addressText, systemImage: "mappin.and.ellipse")
        .font(.subheadline)
        .foregroundStyle(.secondary)
      RatingView(rating: presenter.detail?.rating ?? presenter.restaurant.rating)
    }
  }

  private var addressText: String {
    guard let detail = presenter.detail else {
      return presenter.restaurant.city
    }
    return "\(detail.city), \(detail.address)"
  }

  @ViewBuilder
  private var stateContent: some View {
    switch presenter.state {
    case .idle, .loading, .empty:
      LoadingStateView(message: "common_loading".localized(), identifier: "detail.loading")
        .frame(minHeight: 160)
    case .failed(let message):
      ErrorStateView(
        message: message,
        identifier: "detail.error",
        retryIdentifier: "detail.retry",
        onRetry: presenter.load
      )
      .frame(minHeight: 200)
    case .loaded:
      if let detail = presenter.detail {
        DetailSections(detail: detail)
      }
    }
  }
}
