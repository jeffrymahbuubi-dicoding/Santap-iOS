import Foundation

extension Bundle {
  static var common: Bundle {
    .module
  }
}

public extension String {
  func localized() -> String {
    localized(in: .common)
  }

  func localized(_ arguments: CVarArg...) -> String {
    localized(in: .common, arguments: arguments)
  }
}

extension String {
  func localized(in bundle: Bundle) -> String {
    NSLocalizedString(self, tableName: "Localizable", bundle: bundle, value: self, comment: "")
  }

  func localized(in bundle: Bundle, arguments: [CVarArg]) -> String {
    String(format: localized(in: bundle), arguments: arguments)
  }
}
