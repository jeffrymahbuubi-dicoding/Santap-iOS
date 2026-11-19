import Foundation

public struct ReviewModel: Equatable {
  public let name: String
  public let review: String
  public let date: String

  public init(name: String, review: String, date: String) {
    self.name = name
    self.review = review
    self.date = date
  }
}
