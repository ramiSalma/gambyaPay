//
//  WalletTransferView.swift
//  DiamaPay
//
//  Created by Bits on 28/9/2025.
//  Updated: Auto-verify recipient on 9 digits and UI optimizations
//

import Contacts
import ContactsUI
import SwiftUI

struct WalletTransferView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - State Variables
    @State private var selectedSource: SourceOfFunds = .wallet
    @State private var selectedWallet: SponsoringWallet? = nil
    @State private var currentBalance: String = ""
    
    @State private var destinationPhone: String = ""
    @State private var bankCode: String = ""
    @State private var recipientName: String = ""
    @State private var amount: String = ""
    @State private var paymentDetails: String = ""
    @State private var pin: String = ""
    
    @State private var showContactPicker = false
    @State private var isVerifying = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Error"
    
    // Transfer management
    @State private var destinationBank = ""
    @State private var calculatedFee: Double = 0.0
    @State private var totalAmountWithFee: Double = 0.0
    @State private var feeRuleIndex = ""
    
    // Withdrawal Fee
    @State private var withdrawalFee: Double = 0.0
    @State private var isWithdrawalFeeEnabled: Bool = false
    @State private var isCalculatingWithdrawalFee = false
    @State private var withdrawalFeeError: String? = nil
    
    // Success dialog state
    @State private var showSuccessDialog = false
    @State private var transactionId = ""
    @State private var transactionDate = ""
    @State private var transactionReference = ""
    
    private let userDataManager = UserDataManager.shared
    private let defaultCurrency = "GNF"
    private let numericCurrency = "324"
    
    @State private var showConfirmationDialog = false
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                DiamaPayHeader(title: "Wallet to Wallet", headerColor: Color(hex: "174EA6"))

                if isLoading {
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blueH))
                            .scaleEffect(1.5)
                        
                        Text("Processing...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Source of Funds View
                            SourceOfFundsView(
                                onSourceChanged: { source in
                                    selectedSource = source
                                    calculateTransferFee()
                                },
                                onWalletChanged: { wallet in
                                    selectedWallet = wallet
                                },
                                onBalanceChanged: { balance in
                                    currentBalance = balance
                                },
                                walletTransferStyle: true
                            )
                            
                            // Recipient Details Card
                            recipientDetailsCard
                            
                            // Withdrawal Fee Card
                            withdrawalFeeCard
                            
                            // Reference Card
                            referenceCard
                            
                            // Submit Button
                            submitButton
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 18)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AppBottomBar(
                onSponsors: {},
                onQR: {},
                onLimits: {},
                onSettings: {}
            )
        }
        .navigationBarHidden(true)
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showContactPicker) {
            ContactPickerView(selectedPhone: $destinationPhone)
        }
        .sheet(isPresented: $showSuccessDialog) {
            TransactionSuccessView(
                transactionId: transactionId,
                transactionDate: transactionDate,
                amount: amount,
                recipientName: recipientName,
                recipientPhone: destinationPhone,
                senderName: userDataManager.getUserName(),
                senderPhone: userDataManager.getPhoneNumber(),
                withdrawalFee: isWithdrawalFeeEnabled ? withdrawalFee : 0.0,
                fee: calculatedFee,
                total: totalAmountWithFee,
                currency: defaultCurrency,
                paymentDetails: paymentDetails,
                onClose: {
                    showSuccessDialog = false
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .overlay(confirmationDialogOverlay)
    }
    
    private var confirmationDialogOverlay: some View {
        Group {
            if showConfirmationDialog {
                TransferConfirmationDialog(
                    amount: amount,
                    withdrawalFee: isWithdrawalFeeEnabled ? withdrawalFee : 0.0,
                    transferFee: calculatedFee,
                    total: totalAmountWithFee,
                    currency: defaultCurrency,
                    recipientName: recipientName,
                    recipientPhone: destinationPhone,
                    paymentDetails: paymentDetails,
                    sourceType: selectedSource,
                    selectedWallet: selectedWallet,
                    isPresented: $showConfirmationDialog,
                    onConfirm: { pinCode in
                        showConfirmationDialog = false
                        processTransfer(with: pinCode)
                    },
                    onCancel: {
                        showConfirmationDialog = false
                    }
                )
            }
        }
    }
    
    // MARK: - Recipient Details Card (Optimized with Auto-Verify)
    private var recipientDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Recipient Details")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "174EA6"))
                
                Rectangle()
                    .fill(Color(hex: "0788B9"))
                    .frame(width: 120, height: 2)
            }
            
            HStack(alignment: .top, spacing: 10) {
                HStack(spacing: 8) {
                    TextField("Recipient Number", text: $destinationPhone)
                        .keyboardType(.numberPad)
                        .font(.system(size: 17, weight: .medium))
                        .padding(.leading, 16)
                        .onChange(of: destinationPhone) {
                            // Limit to 9 digits
                            if destinationPhone.count > 9 {
                                destinationPhone = String(destinationPhone.prefix(9))
                            }
                            
                            // Auto-verify when 9 digits are entered
                            if destinationPhone.count == 9 {
                                verifyRecipient()
                            } else if destinationPhone.count < 9 {
                                // Reset recipient info if digits are deleted
                                resetVerificationFields()
                            }
                        }
                    
                    if isVerifying {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blueH))
                            .scaleEffect(0.8)
                            .padding(.trailing, 12)
                    } else if !recipientName.isEmpty && destinationPhone.count == 9 {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blueH)
                            .padding(.trailing, 12)
                    }
                }
                .frame(height: 60)
                .background(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "505A69"), lineWidth: 1.2))
                .cornerRadius(14)
                
                Button(action: { showContactPicker = true }) {
                    VStack(spacing: 4) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "0788B9"))
                            .frame(width: 60, height: 60)
                            .background(Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "0788B9"), lineWidth: 1.2))
                            .cornerRadius(14)
                        Text("Contacts")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "174EA6"))
                    }
                }
            }
            
            HStack(spacing: 8) {
                Text(recipientName.isEmpty ? "Recipient Name" : recipientName)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(recipientName.isEmpty ? Color.secondary : Color.primary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 60)
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "505A69"), lineWidth: 1.2))
            .cornerRadius(14)

            amountCard
        }
        .padding(22)
        .background(Color.white)
        .cornerRadius(22)
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.gray.opacity(0.12), lineWidth: 1))
        .shadow(color: .black.opacity(0.10), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Amount Card
    private var amountCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Amount")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "174EA6"))
                
                Rectangle()
                    .fill(Color(hex: "0788B9"))
                    .frame(width: 120, height: 2)
            }
            
            TextField("Amount *", text: Binding(
                get: {
                    formatAmountInput(amount)
                },
                set: { newValue in
                    let clean = newValue.replacingOccurrences(of: " ", with: "")
                        .replacingOccurrences(of: ",", with: ".")
                        .components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted)
                        .joined()

                    if clean.components(separatedBy: ".").count > 2 {
                        return
                    }

                    amount = clean
                }
            ))
            .keyboardType(.decimalPad)
            .font(.system(size: 17, weight: .medium))
            .padding(.horizontal, 16)
            .frame(height: 60)
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "505A69"), lineWidth: 1.2))
            .cornerRadius(14)
            .onChange(of: amount) {
                NSObject.cancelPreviousPerformRequests(withTarget: self)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.calculateWithdrawalFee()
                }
            }
        }
    }
    
    private func formatAmountInput(_ value: String) -> String {
        let clean = value.replacingOccurrences(of: " ", with: "")
        guard let number = Double(clean) else { return value }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.locale = Locale(identifier: "fr_FR")

        return formatter.string(from: NSNumber(value: number)) ?? value
    }

    // MARK: - Withdrawal Fee Card
    private var withdrawalFeeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Add withdrawal fee")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                    
                    if isCalculatingWithdrawalFee {
                        HStack(spacing: 4) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blueH))
                                .scaleEffect(0.7)
                            Text("Calculating...")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    } else if let error = withdrawalFeeError {
                        Text(error)
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                    } else if withdrawalFee > 0 {
                        Text("Fee: \(formatAmount(withdrawalFee))")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    } else if !amount.isEmpty {
                        Text("No fee applies")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    } else {
                        Text("Enter an amount to see the fee")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Toggle("", isOn: $isWithdrawalFeeEnabled)
                    .labelsHidden()
                    .disabled(withdrawalFee == 0.0 || amount.isEmpty)
                    .onChange(of: isWithdrawalFeeEnabled) {
                        calculateTransferFee()
                    }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(22)
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.gray.opacity(0.12), lineWidth: 1))
        .shadow(color: .black.opacity(0.10), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Reference Card
    private var referenceCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Reason (optional)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "174EA6"))
                
                Rectangle()
                    .fill(Color(hex: "0788B9"))
                    .frame(width: 120, height: 2)
            }
            
            TextField("Enter reason", text: $paymentDetails)
            .font(.system(size: 17, weight: .medium))
            .padding(.horizontal, 16)
            .frame(height: 60)
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "505A69"), lineWidth: 1.2))
            .cornerRadius(14)
        }
        .padding(22)
        .background(Color.white)
        .cornerRadius(22)
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.gray.opacity(0.12), lineWidth: 1))
        .shadow(color: .black.opacity(0.10), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Submit Button
    private var submitButton: some View {
        Button(action: {
            validateAndShowConfirmation()
        }) {
            Text("Submit")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(hex: "174EA6"))
                .cornerRadius(14)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Helper Functions
    
    private func calculateWithdrawalFee() {
        let cleanAmount = amount.cleanCurrencyValue()
        
        guard !cleanAmount.isEmpty,
              let amountValue = Double(cleanAmount),
              amountValue > 0 else {
            withdrawalFee = 0.0
            withdrawalFeeError = nil
            isWithdrawalFeeEnabled = false
            calculatedFee = 0.0
            totalAmountWithFee = 0.0
            return
        }
        
        isCalculatingWithdrawalFee = true
        withdrawalFeeError = nil
        
        var request = FeeCalculationRequest()
        request.processingCode = "22"
        request.bankCode = "00100"
        request.actionCode = "DEB"
        request.currencyCode = "324"
        request.transactionAmount = amountValue
        request.walletProductCode = "001"
        request.walletType = "P"
        request.origin = "W"
        request.messageType = "ON_US"
        
        APIClient.shared.calculateWithdrawalFee(request: request) { result in
            DispatchQueue.main.async {
                self.isCalculatingWithdrawalFee = false
                
                switch result {
                case .success(let response):
                    if response.respCode == "000" || response.respCode == "001" {
                        self.withdrawalFee = response.feeAmount ?? 0.0
                        if self.withdrawalFee == 0 {
                            self.isWithdrawalFeeEnabled = false
                        }
                        self.calculateTransferFee()
                    } else {
                        self.withdrawalFee = 0.0
                        self.isWithdrawalFeeEnabled = false
                        self.withdrawalFeeError = response.message
                        self.calculateTransferFee()
                    }
                    
                case .failure(_):
                    self.withdrawalFee = 0.0
                    self.isWithdrawalFeeEnabled = false
                    self.withdrawalFeeError = "Impossible de calculer"
                    self.calculateTransferFee()
                }
            }
        }
    }
    
    private func calculateTransferFee() {
        let cleanAmount = amount.cleanCurrencyValue()
        
        guard !cleanAmount.isEmpty,
              let amountValue = Double(cleanAmount),
              amountValue > 0 else {
            calculatedFee = 0.0
            totalAmountWithFee = 0.0
            return
        }
        
        let withdrawalFeeValue = isWithdrawalFeeEnabled ? withdrawalFee : 0.0
        let amountWithWithdrawalFee = amountValue + withdrawalFeeValue
        
        let processingCode = selectedSource == .wallet ? "41" : "10"
        
        var request = FeeCalculationRequest()
        request.processingCode = processingCode
        request.bankCode = destinationBank.isEmpty ? "00100" : destinationBank
        request.actionCode = "DEB"
        request.currencyCode = "324"
        request.transactionAmount = amountWithWithdrawalFee
        request.walletProductCode = "001"
        request.walletType = "P"
        request.origin = "W"
        request.messageType = (destinationBank.isEmpty || destinationBank == "00100") ? "ON_US" : "OFF_US"
        
        APIClient.shared.calculateTransactionFee(request: request) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.respCode == "000" || response.respCode == "001" {
                        self.calculatedFee = response.result?.feeAmount ?? 0.0
                        self.feeRuleIndex = response.result?.ruleIndex ?? ""
                        self.totalAmountWithFee = amountValue + withdrawalFeeValue + self.calculatedFee
                    } else {
                        self.calculatedFee = 0.0
                        self.totalAmountWithFee = amountValue + withdrawalFeeValue
                    }
                    
                case .failure(_):
                    self.calculatedFee = 0.0
                    self.totalAmountWithFee = amountValue + withdrawalFeeValue
                }
            }
        }
    }
    
    private func verifyRecipient() {
        guard destinationPhone.count == 9 else {
            return
        }
        
        isVerifying = true
        
        var request = RequestNameEnquiry()
        request.source = "P"
        request.phoneNumber = destinationPhone
        request.bank = "00100"
        request.pin = userDataManager.getPinForAPI()
        request.requestId = generateRequestId()
        request.requestDate = formatCurrentDate()
        request.entityId = userDataManager.getUserCode()
        
        APIClient.shared.getWalletInfo(request: request) { result in
            DispatchQueue.main.async {
                self.isVerifying = false
                
                switch result {
                case .success(let response):
                    if response.respCode == "000" {
                        if let resultData = response.result {
                            self.recipientName = resultData["walletHolder"] as? String ?? ""
                            self.bankCode = resultData["bankCode"] as? String ?? "00100"
                            self.destinationBank = self.bankCode
                            self.calculateTransferFee()
                        }
                    } else {
                        self.showError(message: response.message ?? "Recipient verification failed")
                        self.resetVerificationFields()
                    }
                    
                case .failure(let error):
                    self.showError(message: error.localizedDescription)
                    self.resetVerificationFields()
                }
            }
        }
    }
    
    private func validateAndShowConfirmation() {
        guard !destinationPhone.isEmpty else {
            showError(message: "The recipient's phone number is required")
            return
        }
        
        guard !recipientName.isEmpty else {
            showError(message: "Please verify the recipient")
            return
        }
        
        guard !amount.isEmpty else {
            showError(message: "The amount is required")
            return
        }
        
        let cleanAmount = amount.replacingOccurrences(of: ",", with: ".")
        guard let amountValue = Double(cleanAmount), amountValue > 0 else {
            showError(message: "Invalid amount")
            return
        }
        
        calculateTransferFee()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.showConfirmationDialog = true
        }
    }
    
    private func processTransfer(with pinCode: String) {
        isLoading = true
        
        var request = RequestWalletToWallet()
        request.source = "P"
        request.srcWalletNumber = userDataManager.getWalletNumber()
        request.srcPhoneNumber = userDataManager.getPhoneNumber()
        request.srcBank = "00100"
        
        if selectedSource == .sponsor, let wallet = selectedWallet {
            request.sponsorWallet = wallet.walletNumber
        }
        
        let baseAmount = Double(amount.cleanCurrencyValue()) ?? 0.0
        let withdrawalFeeValue = isWithdrawalFeeEnabled ? withdrawalFee : 0.0
        let finalAmount = baseAmount + withdrawalFeeValue
        request.amount = String(finalAmount)
        
        request.currency = numericCurrency
        request.desWalletNumber = ""
        request.desPhoneNumber = destinationPhone
        request.desBank = destinationBank
        request.reason = String(paymentDetails.prefix(25))
        request.pin = pinCode
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyMMdd"
        let datePrefix = dateFormatter.string(from: Date())
        let randomDigits = String(format: "%06d", Int.random(in: 0...999999))
        let requestId = String((datePrefix + randomDigits).prefix(12))
        request.requestId = requestId
        
        let fullDateFormatter = DateFormatter()
        fullDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        request.requestDate = fullDateFormatter.string(from: Date())
        request.entityId = UserDataManager.shared.getUserCode()
        
        APIClient.shared.transferWalletToWallet(request: request) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.respCode == "000" {
                        self.handleTransferSuccess(response, requestId: requestId)
                    } else {
                        self.showError(message: "Transfer failed: \(response.message ?? "Unknown error")")
                    }
                case .failure(let error):
                    self.showError(message: error.localizedDescription)
                }
            }
        }
    }
    
    private func handleTransferSuccess(_ response: ResponseServiceJson, requestId: String) {
        transactionId = requestId
        transactionReference = response.result?["transactionReference"] as? String ?? requestId
        transactionDate = formatCurrentDateTime()
        showSuccessDialog = true
    }
    
    private func resetVerificationFields() {
        recipientName = ""
        bankCode = ""
        destinationBank = ""
        calculatedFee = 0.0
        totalAmountWithFee = 0.0
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "fr_FR")
        return (formatter.string(from: NSNumber(value: amount)) ?? "0") + " " + defaultCurrency
    }
    
    private func generateRequestId() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyMMdd"
        let datePrefix = dateFormatter.string(from: Date())
        let randomDigits = String(format: "%06d", Int.random(in: 0...999999))
        return datePrefix + randomDigits
    }
    
    private func formatCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: Date())
    }
    
    private func formatCurrentDateTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        return formatter.string(from: Date())
    }
    
    private func showError(message: String) {
        alertTitle = "Error"
        alertMessage = message
        showAlert = true
    }
}


struct ContactPickerView: UIViewControllerRepresentable {
    @Binding var selectedPhone: String
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
                parent.selectedPhone = String(cleanedNumber.suffix(9))
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
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                        .padding(.top, 20)
                    
                    Text("Transfer Successful")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
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
                                            .foregroundColor(.secondary)
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
                                            .foregroundColor(.secondary)
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
                                            .foregroundColor(.secondary)
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
                                    .foregroundColor(.primary)
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
                            .background(Color.blueH)
                            .cornerRadius(8)
                        }
                        
                        Button(action: onClose) {
                            Text("Close")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.blueH)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.blueH.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .navigationBarItems(trailing: Button("Close", action: onClose))
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
            .foregroundColor(.blueH)
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
                .foregroundColor(.secondary)
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
