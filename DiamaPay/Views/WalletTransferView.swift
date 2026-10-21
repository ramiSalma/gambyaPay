import Contacts
import ContactsUI
import SwiftUI

struct WalletTransferView: View {
    @Environment(\.presentationMode) var presentationMode
    var onOpenSettings: () -> Void = {}
    @State private var selectedSource: SourceOfFunds = .wallet
    @State private var selectedWallet: SponsoringWallet?
    @State private var destinationPhone = ""
    @State private var recipientKind: WalletTransferRecipientKind = .phoneOrCustomerID
    @State private var selectedBeneficiary: WalletBeneficiary?
    @State private var recipientName = ""
    @State private var verifiedRecipientKey = ""
    @State private var amount = ""
    @State private var paymentDetails = ""
    @State private var showContactPicker = false
    @State private var showSavedRecipients = false
    @State private var showSponsors = false
    @State private var showQR = false
    @State private var showLimits = false
    @State private var verificationID = UUID()
    @State private var isVerifying = false
    @State private var verificationError: String?
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Error"
    @State private var isSavingBeneficiary = false
    @State private var calculatedFee = 0.0
    @State private var totalAmountWithFee = 0.0
    @State private var confirmedQuoteKey = ""
    @State private var showConfirmationDialog = false
    @State private var showSuccessDialog = false
    @State private var transactionId = ""
    @State private var transactionDate = ""

    private let user = UserDataManager.shared
    private let blue = Color(hex: "174EA6")
    private let cyan = Color(hex: "0788B9")
    private var recipientIdentifier: String { WalletTransferRecipient.normalize(destinationPhone) }
    private var recipientBank: String {
        if let saved = selectedBeneficiary,
           WalletTransferRecipient.normalize(saved.destination ?? "") == recipientIdentifier,
           let bank = saved.destBankCode, !bank.isEmpty { return bank }
        return "00100"
    }
    private var recipientKey: String { recipientKind.rawValue + "|" + recipientIdentifier + "|" + recipientBank }
    private var quoteKey: String {
        recipientKey + "|" + amount + "|" + (selectedSource == .wallet ? "wallet" : "sponsor") + "|" + (selectedWallet?.walletNumber ?? "")
    }
    private var amountValue: Double? { Double(amount) }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(spacing: 0) {
                DiamaPayHeader(title: "Wallet to Wallet", headerColor: blue)
                ScrollView {
                    VStack(spacing: 24) {
                        SourceOfFundsView(
                            onSourceChanged: { source in
                                selectedSource = source
                                if source == .wallet { selectedWallet = nil }
                            },
                            onWalletChanged: { selectedWallet = $0 },
                            walletTransferStyle: true
                        )
                        recipientDetailsCard
                        referenceCard
                        Button(action: prepareConfirmation) {
                            Text("Submit")
                                .font(.system(size: 19, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 170, height: 54)
                                .background(blue)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .disabled(isLoading || isVerifying)
                        .opacity(isLoading || isVerifying ? 0.6 : 1)
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 44)
                }
                .scrollDismissesKeyboard(.interactively)
                .disabled(isLoading || showConfirmationDialog)
            }
            if isLoading {
                Color.black.opacity(0.15).ignoresSafeArea()
                ProgressView("Processing...")
                    .padding(28)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AppBottomBar(
                onSponsors: { showSponsors = true }, onQR: { showQR = true },
                onLimits: { showLimits = true },
                onSettings: { presentationMode.wrappedValue.dismiss(); onOpenSettings() },
                onHome: { presentationMode.wrappedValue.dismiss() }
            )
            .disabled(isLoading || showConfirmationDialog)
        }
        .background {
            NavigationLink("", destination: SponsoringWalletListView(), isActive: $showSponsors).hidden()
            NavigationLink("", destination: QRPaymentView(), isActive: $showQR).hidden()
            NavigationLink("", destination: CheckLimitView(onOpenSettings: onOpenSettings), isActive: $showLimits).hidden()
        }
        .navigationBarHidden(true)
        .alert(alertTitle, isPresented: $showAlert) {
            if alertTitle == "Save recipient?" {
                Button("Save") { saveCurrentBeneficiary() }
                Button("Not now", role: .cancel) { presentationMode.wrappedValue.dismiss() }
            } else {
                Button("OK", role: .cancel) { }
            }
        } message: { Text(alertMessage) }
        .sheet(isPresented: $showContactPicker) {
            ContactPickerView(selectedPhone: $destinationPhone, normalizePhone: WalletTransferRecipient.normalize)
        }
        .sheet(isPresented: $showSavedRecipients) {
            SavedWalletRecipientsView { beneficiary in
                selectedBeneficiary = beneficiary
                destinationPhone = WalletTransferRecipient.normalize(beneficiary.destination ?? "")
            }
        }
        .sheet(isPresented: $showSuccessDialog) {
            TransactionSuccessView(
                transactionId: transactionId, transactionDate: transactionDate,
                amount: amount, recipientName: recipientName, recipientPhone: recipientIdentifier,
                senderName: user.getUserName(), senderPhone: user.getPhoneNumber(),
                withdrawalFee: 0, fee: calculatedFee, total: totalAmountWithFee,
                currency: "GMD", paymentDetails: paymentDetails,
                onClose: {
                    showSuccessDialog = false
                    alertTitle = "Save recipient?"
                    alertMessage = "Would you like to save \(recipientName) for future transfers?"
                    showAlert = true
                }
            )
        }
        .overlay {
            if showConfirmationDialog {
                TransferConfirmationDialog(
                    amount: amount, withdrawalFee: 0, transferFee: calculatedFee,
                    total: totalAmountWithFee, currency: "GMD", recipientName: recipientName,
                    recipientPhone: recipientIdentifier, paymentDetails: paymentDetails,
                    sourceType: selectedSource, selectedWallet: selectedWallet,
                    isPresented: $showConfirmationDialog,
                    onConfirm: { pin in showConfirmationDialog = false; processTransfer(pin: pin) },
                    onCancel: { showConfirmationDialog = false }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showConfirmationDialog)
        .onChange(of: recipientKey) {
            verificationID = UUID()
            recipientName = ""
            verifiedRecipientKey = ""
            verificationError = nil
            isVerifying = false
        }
        .task(id: recipientKey) {
            let key = recipientKey
            guard WalletTransferRecipient.isValid(destinationPhone) else { return }
            do { try await Task.sleep(nanoseconds: 500_000_000) } catch { return }
            guard !Task.isCancelled, key == recipientKey else { return }
            verifyRecipient(key: key)
        }
    }

    private var recipientDetailsCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionTitle("Recipient Details")
            Picker("Recipient identifier", selection: $recipientKind) {
                ForEach(WalletTransferRecipientKind.allCases, id: \.self) { kind in
                    Text(kind.title).tag(kind)
                }
            }
            .pickerStyle(.segmented)
            HStack(alignment: .top, spacing: 8) {
                HStack(spacing: 4) {
                    TextField(recipientKind == .wallet ? "Wallet Number" : "Phone or Customer ID", text: $destinationPhone)
                        .keyboardType(.default)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(size: 15))
                        .accessibilityLabel("Recipient number")
                    if isVerifying { ProgressView().scaleEffect(0.8) }
                    else if verifiedRecipientKey == recipientKey && !recipientName.isEmpty {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    }
                }
                .padding(.horizontal, 12)
                .frame(height: 52)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "505A69"), lineWidth: 1.2))
                recipientButton("Saved", icon: "book.closed.fill") { showSavedRecipients = true }
                recipientButton("Contacts", icon: "person.crop.rectangle.fill") { recipientKind = .phoneOrCustomerID; showContactPicker = true }
            }
            Text(recipientName.isEmpty ? "Recipient Name" : recipientName)
                .foregroundColor(recipientName.isEmpty ? .secondary : .primary)
                .font(.system(size: 16))
                .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                .padding(.horizontal, 12)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "505A69"), lineWidth: 1.2))
            if let verificationError {
                VStack(alignment: .leading, spacing: 6) {
                    Text(verificationError).font(.caption).foregroundColor(.red)
                    Button("Verify Again") { verifyRecipient(key: recipientKey) }.font(.caption)
                }
            }
            TextField("Amount *", text: $amount)
                .keyboardType(.decimalPad)
                .font(.system(size: 16))
                .padding(.horizontal, 12)
                .frame(height: 52)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "505A69"), lineWidth: 1.2))
                .onChange(of: amount) {
                    let cleaned = amount.replacingOccurrences(of: ",", with: ".").filter { $0.isASCII && ($0.isNumber || $0 == ".") }
                    if cleaned != amount { amount = cleaned }
                }
        }
        .padding(18)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.12), lineWidth: 1))
        .shadow(color: .black.opacity(0.12), radius: 5, x: 0, y: 4)
    }

    private var referenceCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionTitle("Reason (optional)")
            TextField("Enter reason", text: $paymentDetails)
                .padding(.horizontal, 12)
                .frame(height: 52)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "505A69"), lineWidth: 1.2))
                .onChange(of: paymentDetails) { paymentDetails = String(paymentDetails.prefix(25)) }
        }
        .padding(18)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.12), lineWidth: 1))
        .shadow(color: .black.opacity(0.12), radius: 5, x: 0, y: 4)
    }

    private func sectionTitle(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 17, weight: .bold)).foregroundColor(blue)
            Rectangle().fill(cyan).frame(width: 64, height: 2)
        }
    }

    private func recipientButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 23))
                    .frame(width: 46, height: 52)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(cyan, lineWidth: 1.2))
                Text(title).font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(cyan)
        }
        .accessibilityLabel(title == "Saved" ? "Choose saved recipient" : "Choose phone contact")
    }

    private func verifyRecipient(key: String) {
        guard WalletTransferRecipient.isValid(destinationPhone), key == recipientKey else { return }
        let currentVerificationID = UUID()
        verificationID = currentVerificationID
        isVerifying = true
        verificationError = nil
        verifiedRecipientKey = ""
        recipientName = ""
        let identifier = recipientIdentifier
        var request = RequestNameEnquiry()
        request.source = recipientKind.source
        request.walletNumber = request.source == "W" ? identifier : ""
        request.phoneNumber = request.source == "P" ? identifier : ""
        request.bank = recipientBank
        request.entityId = user.getUserCode()
        request.requestId = requestId()
        request.requestDate = timestamp()
        APIClient.shared.getWalletInfo(request: request) { result in
            DispatchQueue.main.async {
                guard key == recipientKey, currentVerificationID == verificationID else { return }
                isVerifying = false
                switch result {
                case .success(let response):
                    guard response.respCode == "000",
                          let name = response.result?["walletHolder"] as? String,
                          !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        verificationError = response.message ?? "Unable to verify this recipient."
                        return
                    }
                    recipientName = name
                    verifiedRecipientKey = key
                case .failure(let error):
                    verificationError = (error as? APIError)?.message ?? "Unable to verify the recipient. Please try again."
                }
            }
        }
    }

    private func validateTransfer() -> Bool {
        guard WalletTransferRecipient.isValid(destinationPhone) else {
            showError("Enter the recipient phone number, customer ID, or wallet number."); return false
        }
        guard verifiedRecipientKey == recipientKey, !recipientName.isEmpty, !isVerifying else {
            showError("Please verify the recipient first."); return false
        }
        guard recipientIdentifier != WalletTransferRecipient.normalize(user.getPhoneNumber()),
              recipientIdentifier != user.getWalletNumber() else {
            showError("Please choose another recipient."); return false
        }
        guard let value = amountValue, value.isFinite, value > 0,
              amount.components(separatedBy: ".").count <= 2,
              (amount.split(separator: ".", omittingEmptySubsequences: false).last?.count ?? 0) <= (amount.contains(".") ? 2 : amount.count) else {
            showError("Enter a valid amount with up to two decimal places."); return false
        }
        if selectedSource == .sponsor && (selectedWallet?.walletNumber.isEmpty != false) {
            showError("Select a sponsor first."); return false
        }
        return true
    }

    private func prepareConfirmation() {
        guard !isLoading, validateTransfer(), let value = amountValue else { return }
        isLoading = true
        let key = quoteKey
        let request = WalletFeeQuoteRequest.current(
            amount: value, destination: recipientIdentifier,
            transactionType: selectedSource == .wallet ? "41" : "10", destinationBank: recipientBank
        )
        APIClient.shared.calculateWalletFee(request: request) { result in
            DispatchQueue.main.async {
                isLoading = false
                guard key == quoteKey else { return }
                switch result {
                case .success(let response):
                    guard response.respCode == "000", let quote = response.result,
                          let fee = quote.feeAmount, fee.isFinite, fee >= 0,
                          (quote.taxAmount ?? 0).isFinite, (quote.taxAmount ?? 0) >= 0 else {
                        showError(response.message ?? "Unable to calculate fees."); return
                    }
                    let total = quote.totalAmount ?? (value + quote.totalFees)
                    guard total.isFinite, total >= value else { showError("Invalid fee quote. Please try again."); return }
                    calculatedFee = quote.totalFees
                    totalAmountWithFee = total
                    confirmedQuoteKey = key
                    showConfirmationDialog = true
                case .failure(let error):
                    showError((error as? APIError)?.message ?? "Unable to calculate fees. Please try again.")
                }
            }
        }
    }

    private func processTransfer(pin: String) {
        guard !isLoading, validateTransfer(), let value = amountValue else { return }
        guard confirmedQuoteKey == quoteKey else {
            showError("Transfer details changed. Please submit again."); return
        }
        guard !pin.isEmpty else { showError("Enter your PIN."); return }
        isLoading = true
        var request = RequestWalletToWallet()
        request.srcWalletNumber = user.getWalletNumber()
        request.srcPhoneNumber = user.getPhoneNumber()
        request.source = request.srcWalletNumber.isEmpty ? "P" : "W"
        request.srcBank = user.getBankCode().isEmpty ? "00100" : user.getBankCode()
        request.desWalletNumber = recipientKind == .wallet ? recipientIdentifier : ""
        request.desPhoneNumber = request.desWalletNumber.isEmpty ? recipientIdentifier : ""
        request.desBank = recipientBank
        request.amount = String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), value)
        request.currency = "270"
        request.reason = String(paymentDetails.prefix(25))
        request.pin = pin
        request.sponsorWallet = selectedSource == .sponsor ? selectedWallet?.walletNumber : nil
        request.requestId = requestId()
        request.requestDate = timestamp()
        request.entityId = user.getUserCode()
        let sentRequestId = request.requestId
        APIClient.shared.transferWalletToWallet(request: request) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let response):
                    guard response.respCode == "000" else { showError(response.message ?? "Transfer failed."); return }
                    transactionId = response.resultString ?? (response.result?["transactionReference"] as? String) ?? response.authCode ?? sentRequestId
                    transactionDate = DateFormatter.with(format: "dd/MM/yyyy HH:mm").string(from: Date())
                    confirmedQuoteKey = ""
                    showSuccessDialog = true
                case .failure(let error):
                    showError((error as? APIError)?.message ?? "Transfer could not be confirmed. Check transaction history before trying again.")
                }
            }
        }
    }

    private func requestId() -> String {
        DateFormatter.with(format: "yyMMdd").string(from: Date()) + String(format: "%06d", Int.random(in: 0...999999))
    }
    private func timestamp() -> String { DateFormatter.with(format: "yyyy-MM-dd HH:mm:ss").string(from: Date()) }
    private func saveCurrentBeneficiary() {
        guard !isSavingBeneficiary else { return }
        let phoneNumber = user.getPhoneNumber().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !phoneNumber.isEmpty, !recipientIdentifier.isEmpty else {
            showError("Recipient details are unavailable. Please try again.")
            return
        }

        isSavingBeneficiary = true
        let request = WalletBeneficiaryAddRequest(
            phoneNumber: phoneNumber,
            destination: recipientIdentifier,
            institutionCode: recipientBank,
            transactionType: selectedSource == .sponsor ? "10" : "41",
            name: recipientName,
            requestId: requestId(),
            requestDate: timestamp(),
            entityId: user.getUserCode().isEmpty ? phoneNumber : user.getUserCode()
        )
        APIClient.shared.addWalletBeneficiary(request: request) { result in
            DispatchQueue.main.async {
                isSavingBeneficiary = false
                switch result {
                case .success(let response) where response.respCode == "000":
                    presentationMode.wrappedValue.dismiss()
                case .success(let response):
                    alertTitle = "Unable to save recipient"
                    alertMessage = response.message ?? "Please try again later."
                    showAlert = true
                case .failure(let error):
                    alertTitle = "Unable to save recipient"
                    alertMessage = (error as? APIError)?.message ?? "Please check your connection and try again."
                    showAlert = true
                }
            }
        }
    }

    private func showError(_ message: String) {
        alertTitle = "Error"
        alertMessage = message
        showAlert = true
    }
}

struct ContactPickerView: UIViewControllerRepresentable {
    @Binding var selectedPhone: String
    var normalizePhone: (String) -> String = { String($0.suffix(9)) }
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CNContactPickerDelegate {
        let parent: ContactPickerView
        
        init(_ parent: ContactPickerView) {
            self.parent = parent
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contactProperty: CNContactProperty) {
            if let phoneNumber = contactProperty.value as? CNPhoneNumber {
                let cleanedNumber = phoneNumber.stringValue.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                parent.selectedPhone = parent.normalizePhone(cleanedNumber)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

import SwiftUI
import PDFKit

struct TransactionSuccessView: View {
    let transactionId: String
    let transactionDate: String
    let amount: String
    let recipientName: String
    let recipientPhone: String
    let senderName: String
    let senderPhone: String
    let withdrawalFee: Double
    let fee: Double
    let total: Double
    let currency: String
    let paymentDetails: String
    let onClose: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 34, weight: .medium))
                            .foregroundColor(Color(hex: "16845B"))
                            .frame(width: 54, height: 54)
                            .background(Color(hex: "E8F5EF"))
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Transfer successful")
                                .font(.system(size: 21, weight: .bold))
                                .foregroundColor(Color(hex: "172B4D"))
                            Text("Your transfer is complete.")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "667085"))
                            Text((Double(amount.cleanCurrencyValue()) ?? 0).formatAsCurrency() + " " + currency)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(hex: "174EA6"))
                                .padding(.top, 4)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "E5E9EF"), lineWidth: 1))
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Group {
                            SectionHeader(title: "Transaction Information")
                            DetailRow(label: "ID Transaction:", value: transactionId)
                            DetailRow(label: "Date:", value: transactionDate)
                        }
                        
                        Divider().padding(.vertical, 8)
                        
                        Group {
                            SectionHeader(title: "Amount Details")
                            
                            DetailRow(
                                label: "Amount sent:",
                                value: (Double(amount.cleanCurrencyValue()) ?? 0.0).formatAsCurrency() + " " + currency,
                                valueColor: .primary
                            )
                            
                            if withdrawalFee > 0 {
                                HStack {
                                    HStack(spacing: 6) {
                                        Image(systemName: "banknote")
                                            .font(.system(size: 14))
                                            .foregroundColor(.orange)
                                        Text("Withdrawal fee:")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Color(hex: "667085"))
                                    }
                                    Spacer()
                                    Text(formatAmount(withdrawalFee))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.orange)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            if fee > 0 {
                                HStack {
                                    HStack(spacing: 6) {
                                        Image(systemName: "paperplane.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.blueH)
                                        Text("Transfer fee:")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Color(hex: "667085"))
                                    }
                                    Spacer()
                                    Text(formatAmount(fee))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.blueH)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.blueH.opacity(0.1))
                                .cornerRadius(8)
                            } else {
                                HStack {
                                    HStack(spacing: 6) {
                                        Image(systemName: "paperplane.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.green)
                                        Text("Transfer fee:")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Color(hex: "667085"))
                                    }
                                    Spacer()
                                    Text("Free")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.green)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            HStack {
                                Text("Total debited:")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Color(hex: "263445"))
                                Spacer()
                                Text(formatAmount(total))
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.blueH)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.blueH.opacity(0.05))
                            .cornerRadius(8)
                        }
                        
                        Divider().padding(.vertical, 8)
                        
                        Group {
                            SectionHeader(title: "Sender")
                            DetailRow(label: "Name:", value: senderName)
                            DetailRow(label: "Phone:", value: senderPhone)
                        }
                        
                        Divider().padding(.vertical, 8)
                        
                        Group {
                            SectionHeader(title: "Recipient")
                            DetailRow(label: "Name:", value: recipientName)
                            DetailRow(label: "Phone:", value: recipientPhone)
                            
                            if !paymentDetails.isEmpty {
                                DetailRow(label: "Reason:", value: paymentDetails)
                            }
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    VStack(spacing: 12) {
                        Button(action: { shareReceipt() }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share receipt")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "174EA6"))
                            .cornerRadius(10)
                        }
                        
                        Button(action: onClose) {
                            Text("Close")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(hex: "174EA6"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(hex: "EAF1FB"))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .navigationBarItems(trailing: Button("Close", action: onClose).foregroundColor(Color(hex: "174EA6")))
            .navigationBarTitle("Transfer Receipt", displayMode: .inline)
        }
    }
    
    private func formatAmount(_ amount: Double) -> String {
        return amount.formatAsCurrency() + " " + currency
    }
    
    private func shareReceipt() {
        let pdfData = generatePDF()
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "Transfer_Receipt_\(transactionId).pdf"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try pdfData.write(to: fileURL)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootVC = windowScene.windows.first?.rootViewController else {
                    return
                }
                
                var topVC = rootVC
                while let presented = topVC.presentedViewController {
                    topVC = presented
                }
                
                let activityViewController = UIActivityViewController(
                    activityItems: [fileURL],
                    applicationActivities: nil
                )
                
                if let popover = activityViewController.popoverPresentationController {
                    popover.sourceView = topVC.view
                    popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                
                topVC.present(activityViewController, animated: true)
            }
        } catch {
            //print("Error saving PDF: \(error)")
        }
    }
    
    private func generatePDF() -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "DIAMACASH",
            kCGPDFContextAuthor: senderName,
            kCGPDFContextTitle: "Transfer Receipt"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = 60
            let leftMargin: CGFloat = 50
            let rightMargin: CGFloat = 545
            
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            let title = "REÇU DE TRANSFERT"
            title.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: titleAttributes)
            yPosition += 40
            
            context.cgContext.setStrokeColor(UIColor.black.cgColor)
            context.cgContext.setLineWidth(2)
            context.cgContext.move(to: CGPoint(x: leftMargin, y: yPosition))
            context.cgContext.addLine(to: CGPoint(x: rightMargin, y: yPosition))
            context.cgContext.strokePath()
            yPosition += 30
            
            let contentAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.black
            ]
            
            let boldAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor.black
            ]
            
            drawText("Status: Transfer successful", at: CGPoint(x: leftMargin, y: yPosition), attributes: contentAttributes, context: context)
            yPosition += 25
            
            drawText("ID Transaction: \(transactionId)", at: CGPoint(x: leftMargin, y: yPosition), attributes: contentAttributes, context: context)
            yPosition += 25
            
            drawText("Date: \(transactionDate)", at: CGPoint(x: leftMargin, y: yPosition), attributes: contentAttributes, context: context)
            yPosition += 35
            
            drawText("AMOUNT DETAILS", at: CGPoint(x: leftMargin, y: yPosition), attributes: boldAttributes, context: context)
            yPosition += 25
            
            let baseAmount = Double(amount.cleanCurrencyValue()) ?? 0.0
            drawText("Amount sent: \(formatAmount(baseAmount))", at: CGPoint(x: leftMargin, y: yPosition), attributes: contentAttributes, context: context)
            yPosition += 25
            
            if withdrawalFee > 0 {
                drawText("Withdrawal fee: \(formatAmount(withdrawalFee))", at: CGPoint(x: leftMargin, y: yPosition), attributes: contentAttributes, context: context)
                yPosition += 25
            }
            
            drawText("Transfer fee: \(fee > 0 ? formatAmount(fee) : "Free")", at: CGPoint(x: leftMargin, y: yPosition), attributes: contentAttributes, context: context)
            yPosition += 25
            
            drawText("Total debited: \(formatAmount(total))", at: CGPoint(x: leftMargin, y: yPosition), attributes: boldAttributes, context: context)
            yPosition += 35
            
            context.cgContext.setLineWidth(1)
            context.cgContext.move(to: CGPoint(x: leftMargin, y: yPosition))
            context.cgContext.addLine(to: CGPoint(x: rightMargin, y: yPosition))
            context.cgContext.strokePath()
            yPosition += 25
            
            drawText("SENDER", at: CGPoint(x: leftMargin, y: yPosition), attributes: boldAttributes, context: context)
            yPosition += 25
            
            drawText("Name: \(senderName)", at: CGPoint(x: leftMargin, y: yPosition), attributes: contentAttributes, context: context)
            yPosition += 25
            
            drawText("Phone: \(senderPhone)", at: CGPoint(x: leftMargin, y: yPosition), attributes: contentAttributes, context: context)
            yPosition += 35
            
            drawText("RECIPIENT", at: CGPoint(x: leftMargin, y: yPosition), attributes: boldAttributes, context: context)
            yPosition += 25
            
            drawText("Name: \(recipientName)", at: CGPoint(x: leftMargin, y: yPosition), attributes: contentAttributes, context: context)
            yPosition += 25
            
            drawText("Phone: \(recipientPhone)", at: CGPoint(x: leftMargin, y: yPosition), attributes: contentAttributes, context: context)
            yPosition += 35
            
            if !paymentDetails.isEmpty {
                drawText("Reason: \(paymentDetails)", at: CGPoint(x: leftMargin, y: yPosition), attributes: contentAttributes, context: context)
                yPosition += 35
            }
            
            context.cgContext.move(to: CGPoint(x: leftMargin, y: yPosition))
            context.cgContext.addLine(to: CGPoint(x: rightMargin, y: yPosition))
            context.cgContext.strokePath()
            yPosition += 25
            
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.gray
            ]
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy 'at' HH:mm"
            let footerText = "This receipt was generated automatically on \(dateFormatter.string(from: Date()))"
            drawText(footerText, at: CGPoint(x: leftMargin, y: yPosition), attributes: footerAttributes, context: context)
        }
        
        return data
    }
    
    private func drawText(_ text: String, at point: CGPoint, attributes: [NSAttributedString.Key: Any], context: UIGraphicsPDFRendererContext) {
        text.draw(at: point, withAttributes: attributes)
    }
}

// MARK: - Supporting Views
struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(Color(hex: "174EA6"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
    }
}
struct DetailRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary
    var isBold: Bool = false  // ✅ ADD THIS
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "667085"))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(value)
                .font(.system(size: 14, weight: isBold ? .bold : .semibold))  // ✅ CHANGE THIS
                .foregroundColor(valueColor)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .multilineTextAlignment(.trailing)
        }
    }
}
#Preview {
    WalletTransferView()
}
