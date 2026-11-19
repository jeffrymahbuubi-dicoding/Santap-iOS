import SwiftUI

public struct RemoteImageView: View {
  private let url: URL?

  public init(url: URL?) {
    self.url = url
  }

  public var body: some View {
    Color(.secondarySystemFill)
      .overlay { content }
      .clipped()
      .accessibilityHidden(true)
  }

  @ViewBuilder
  private var content: some View {
    if let url {
      AsyncImage(url: url) { phase in
        switch phase {
        case .success(let image):
          image
            .resizable()
            .scaledToFill()
        case .failure:
          placeholder
        default:
          ProgressView()
        }
      }
    } else {
      placeholder
    }
  }

  private var placeholder: some View {
    Image(systemName: "fork.knife")
      .font(.title2)
      .foregroundStyle(.secondary)
  }
}
