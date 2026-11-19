import SwiftUI

public struct LoadingStateView: View {
  private let message: String
  private let identifier: String

  public init(message: String, identifier: String) {
    self.message = message
    self.identifier = identifier
  }

  public var body: some View {
    VStack(spacing: 12) {
      ProgressView()
      Text(message)
        .font(.body)
        .foregroundStyle(.secondary)
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier(identifier)
  }
}

public struct ErrorStateView: View {
  private let message: String
  private let identifier: String
  private let retryIdentifier: String
  private let onRetry: () -> Void

  public init(message: String, identifier: String, retryIdentifier: String, onRetry: @escaping () -> Void) {
    self.message = message
    self.identifier = identifier
    self.retryIdentifier = retryIdentifier
    self.onRetry = onRetry
  }

  public var body: some View {
    VStack(spacing: 12) {
      Image(systemName: "wifi.exclamationmark")
        .font(.largeTitle)
        .foregroundStyle(.secondary)
      Text(message)
        .font(.body)
        .multilineTextAlignment(.center)
      Button("common_retry".localized(), action: onRetry)
        .buttonStyle(.bordered)
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityIdentifier(retryIdentifier)
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier(identifier)
  }
}

public struct EmptyStateView: View {
  private let systemImage: String
  private let title: String
  private let subtitle: String?
  private let identifier: String

  public init(systemImage: String, title: String, subtitle: String?, identifier: String) {
    self.systemImage = systemImage
    self.title = title
    self.subtitle = subtitle
    self.identifier = identifier
  }

  public var body: some View {
    VStack(spacing: 8) {
      Image(systemName: systemImage)
        .font(.largeTitle)
        .foregroundStyle(.secondary)
      Text(title)
        .font(.headline)
        .multilineTextAlignment(.center)
      if let subtitle {
        Text(subtitle)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier(identifier)
  }
}
