import Common
import Restaurant
import SwiftUI

struct DetailSections: View {
  let detail: RestaurantDetailModel

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      if !detail.categories.isEmpty {
        categories
      }
      section(title: "detail_description".localized()) {
        Text(detail.description)
          .font(.body)
      }
      section(title: "detail_menu".localized()) {
        menuList(title: "detail_foods".localized(), items: detail.foods)
        menuList(title: "detail_drinks".localized(), items: detail.drinks)
      }
      section(title: "detail_reviews".localized()) {
        ForEach(Array(detail.reviews.enumerated()), id: \.offset) { _, review in
          reviewRow(review)
        }
      }
    }
  }

  private var categories: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(detail.categories, id: \.self) { category in
          Text(category)
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.accentColor.opacity(0.15)))
        }
      }
    }
  }

  private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.headline)
        .accessibilityAddTraits(.isHeader)
      content()
    }
  }

  private func menuList(title: String, items: [String]) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(.subheadline.bold())
      if items.isEmpty {
        Text("-")
          .foregroundStyle(.secondary)
      } else {
        ForEach(items, id: \.self) { item in
          Text("• \(item)")
            .font(.body)
        }
      }
    }
  }

  private func reviewRow(_ review: ReviewModel) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack {
        Text(review.name)
          .font(.subheadline.bold())
        Spacer()
        Text(review.date)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Text(review.review)
        .font(.body)
    }
    .padding(.vertical, 4)
    .accessibilityElement(children: .combine)
  }
}
