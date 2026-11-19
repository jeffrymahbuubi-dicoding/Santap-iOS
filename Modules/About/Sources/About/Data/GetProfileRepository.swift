import Combine
import Foundation
import SantapCore

public struct GetProfileRepository: Repository {
  private let dataSource: any DataSource<Void, ProfileEntity>
  private let photoName: String

  public init(dataSource: any DataSource<Void, ProfileEntity>, photoName: String = "ProfilePhoto") {
    self.dataSource = dataSource
    self.photoName = photoName
  }

  public func execute(request: Void) -> AnyPublisher<ProfileModel, Error> {
    let photoName = photoName
    return dataSource.execute(request: request)
      .map { ProfileModel(name: $0.name, role: $0.role, photoName: photoName) }
      .eraseToAnyPublisher()
  }
}
