import Foundation

public struct ProfileEntity: Equatable {
  public let name: String
  public let role: String

  public init(name: String, role: String) {
    self.name = name
    self.role = role
  }
}
