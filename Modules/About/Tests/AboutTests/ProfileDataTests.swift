import Combine
import Common
import XCTest
@testable import About

final class ProfileDataTests: XCTestCase {
  private var folder: URL?

  override func tearDown() {
    if let folder {
      try? FileManager.default.removeItem(at: folder)
    }
    folder = nil
    super.tearDown()
  }

  func testReadsNameAndRoleFromTheBundleInfo() throws {
    let bundle = try makeBundle(info: ["ProfileName": " Nama Contoh ", "ProfileRole": "Peran Contoh"])
    let dataSource = ProfileDataSource(bundle: bundle)

    let profile = awaitValue(dataSource.execute(request: ()))

    XCTAssertEqual(profile, ProfileEntity(name: "Nama Contoh", role: "Peran Contoh"))
  }

  func testMissingKeyFailsWithTheKeyName() throws {
    let bundle = try makeBundle(info: ["ProfileName": "Nama Contoh"])
    let dataSource = ProfileDataSource(bundle: bundle)

    XCTAssertEqual(awaitError(dataSource.execute(request: ())) as? ProfileError, .missingValue("ProfileRole"))
  }

  func testBlankValueFails() throws {
    let bundle = try makeBundle(info: ["ProfileName": "   ", "ProfileRole": "Peran"])
    let dataSource = ProfileDataSource(bundle: bundle)

    XCTAssertEqual(awaitError(dataSource.execute(request: ())) as? ProfileError, .missingValue("ProfileName"))
  }

  func testErrorDescriptionComesFromTheCommonStrings() {
    XCTAssertEqual(ProfileError.missingValue("ProfileName").errorDescription, "about_error".localized())
  }

  func testRepositoryMapsToTheDomainWithThePhotoName() {
    let dataSource = StubProfileDataSource(result: .success(ProfileEntity(name: "A", role: "B")))
    let repository = GetProfileRepository(dataSource: dataSource, photoName: "Foto")

    XCTAssertEqual(
      awaitValue(repository.execute(request: ())),
      ProfileModel(name: "A", role: "B", photoName: "Foto")
    )
  }

  func testRepositoryUsesTheDefaultPhotoName() {
    let dataSource = StubProfileDataSource(result: .success(ProfileEntity(name: "A", role: "B")))

    let model = awaitValue(GetProfileRepository(dataSource: dataSource).execute(request: ()))

    XCTAssertEqual(model?.photoName, "ProfilePhoto")
  }

  func testRepositoryPassesTheErrorThrough() {
    let dataSource = StubProfileDataSource(result: .failure(ProfileError.missingValue("ProfileName")))

    XCTAssertEqual(
      awaitError(GetProfileRepository(dataSource: dataSource).execute(request: ())) as? ProfileError,
      .missingValue("ProfileName")
    )
  }

  private func makeBundle(info: [String: String]) throws -> Bundle {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    folder = directory
    let data = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
    try data.write(to: directory.appendingPathComponent("Info.plist"))
    return try XCTUnwrap(Bundle(path: directory.path))
  }
}
