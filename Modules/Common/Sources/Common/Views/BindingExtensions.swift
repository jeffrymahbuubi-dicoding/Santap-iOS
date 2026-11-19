import SwiftUI

public extension Binding where Value == String? {
  var isPresent: Binding<Bool> {
    Binding<Bool>(
      get: { wrappedValue != nil },
      set: { shown in
        if !shown {
          wrappedValue = nil
        }
      }
    )
  }
}
