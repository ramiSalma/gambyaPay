import SwiftUI
import UIKit

extension Binding where Value == String {
    /// Restricts phone input, including pasted text, to at most ten ASCII digits.
    func walletPhoneNumber() -> Binding<String> {
        Binding<String>(
            get: { self.wrappedValue },
            set: { self.wrappedValue = String($0.filter { $0 >= "0" && $0 <= "9" }.prefix(10)) }
        )
    }
}


extension Binding where Value == String {
    /// Filters typing, pasted text, and autofill while preserving leading zeros.
    func digitsOnly(maxLength: Int) -> Binding<String> {
        Binding<String>(
            get: { self.wrappedValue },
            set: { self.wrappedValue = String($0.filter { $0.isASCII && $0.isNumber }.prefix(maxLength)) }
        )
    }
}

/// The wallet PIN is exactly four ASCII digits, including leading zeros.
extension String {
    var isValidWalletPIN: Bool {
        count == 4 && allSatisfy { $0.isASCII && $0.isNumber }
    }
}

extension Binding where Value == String {
    func walletPIN() -> Binding<String> {
        digitsOnly(maxLength: 4)
    }
}

/// Enforces the limit in the native editor, before extra characters can appear.
struct WalletPINField: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String
    var isSecure = true
    var prompt: Text? = nil
    @Environment(\.isEnabled) private var isEnabled

    init(_ placeholder: String, text: Binding<String>, isSecure: Bool = true, prompt: Text? = nil) {
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self.prompt = prompt
    }

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.delegate = context.coordinator
        field.keyboardType = .numberPad
        field.autocorrectionType = .no
        field.spellCheckingType = .no
        field.font = .systemFont(ofSize: 18)
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        field.addTarget(context.coordinator, action: #selector(Coordinator.editingChanged(_:)), for: .editingChanged)
        return field
    }

    func updateUIView(_ field: UITextField, context: Context) {
        context.coordinator.parent = self
        field.placeholder = placeholder
        field.accessibilityLabel = placeholder
        field.isEnabled = isEnabled
        if field.isSecureTextEntry != isSecure { field.isSecureTextEntry = isSecure }
        if field.text != text { field.text = text }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: WalletPINField
        init(_ parent: WalletPINField) { self.parent = parent }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let current = textField.text ?? ""
            guard let swiftRange = Range(range, in: current) else { return false }
            let proposed = current.replacingCharacters(in: swiftRange, with: string)
            let accepted = String(proposed.filter { $0.isASCII && $0.isNumber }.prefix(4))
            // Update the native editor even when the binding's value is unchanged.
            textField.text = accepted
            parent.text = accepted
            return false
        }

        @objc func editingChanged(_ field: UITextField) {
            let accepted = String((field.text ?? "").filter { $0.isASCII && $0.isNumber }.prefix(4))
            if field.text != accepted { field.text = accepted }
            parent.text = accepted
        }
    }
}
