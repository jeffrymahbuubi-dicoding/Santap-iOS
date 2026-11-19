import Foundation

public struct ProfileModel: Equatable {
  public let name: String
  public let role: String
  public let photoName: String

  public init(name: String, role: String, photoName: String) {
    self.name = name
    self.role = role
    self.photoName = photoName
  }
}
