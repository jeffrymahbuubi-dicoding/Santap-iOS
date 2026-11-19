import Common
import SantapCore
import SwiftUI

public struct AboutView: View {
  @ObservedObject private var presenter: AboutPresenter

  public init(presenter: AboutPresenter) {
    self.presenter = presenter
  }

  public var body: some View {
    content
      .navigationTitle("about_title".localized())
      .navigationBarTitleDisplayMode(.inline)
      .onAppear {
        if presenter.value == nil, presenter.state != .loading {
          presenter.load(request: ())
        }
      }
  }

  @ViewBuilder
  private var content: some View {
    if case .failed = presenter.state, presenter.value == nil {
      ErrorStateView(
        message: "about_error".localized(),
        identifier: "about.error",
        retryIdentifier: "about.retry",
        onRetry: { presenter.load(request: ()) }
      )
    } else {
      ScrollView {
        VStack(spacing: 12) {
          if let profile = presenter.value {
            profileHeader(profile)
          } else {
            ProgressView()
              .padding(.top, 48)
          }
          Divider()
          applicationInfo
        }
        .padding(16)
        .readableWidth()
      }
    }
  }

  private var applicationInfo: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("about_app_heading".localized())
        .font(.headline)
        .accessibilityAddTraits(.isHeader)
      Text("about_app_description".localized())
        .font(.body)
      Text("about_data_source".localized())
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func profileHeader(_ profile: ProfileModel) -> some View {
    VStack(spacing: 8) {
      Image(profile.photoName)
        .resizable()
        .scaledToFill()
        .frame(width: 160, height: 160)
        .clipShape(Circle())
        .accessibilityLabel("about_photo_label".localized())
        .accessibilityIdentifier("about.photo")
      Text(profile.name)
        .font(.title2.bold())
        .accessibilityIdentifier("about.name")
      Text(profile.role)
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .padding(.top, 16)
  }
}
