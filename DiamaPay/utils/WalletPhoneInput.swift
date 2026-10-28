import SwiftUI

extension Binding where Value == String {
    /// Restricts phone input, including pasted text, to at most ten ASCII digits.
    func walletPhoneNumber() -> Binding<String> {
        Binding<String>(
            get: { self.wrappedValue },
            set: { self.wrappedValue = String($0.filter { $0 >= "0" && $0 <= "9" }.prefix(10)) }
        )
    }
}
