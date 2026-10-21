//
//  AccountToWalletTransferView.swift
//  DiamaPay
//
//  Created by Bits on 30/9/2025.
//

import SwiftUI
import PDFKit

struct AccountToWalletTransferView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - State Variables
    @State private var linkedAccounts: [Account] = []
    @State private var selectedAccount: Account? = nil
    @State private var showLinkedAccounts = false
    @State private var accountNameVerified: String = ""
    
    @State private var amount: String = ""
    @State private var reference: String = ""
    
    @State private var isLoading = false
    @State private var isVerifying = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Erreur"
    
    // Fee calculation
    @State private var calculatedFee: Double = 0.0
    @State private var totalAmountWithFee: Double = 0.0
    @State private var feeQuoteID = UUID()
    @State private var isCalculatingTransferFee = false
    
    @State private var withdrawalFee: Double = 0.0
    @State private var isWithdrawalFeeEnabled: Bool = false
    
    
    // Success dialog
    @State private var showSuccessDialog = false
    @State private var transactionId = ""
    @State private var transactionDate = ""
    @State private var transactionAmount = ""
    @State private var transactionReference = ""
    
    @State private var showConfirmationDialog = false
    
    private let userDataManager = UserDataManager.shared
    private let defaultCurrency = "GMD"
    private let numericCurrency = "270"
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                DiamaPayHeader(title: "Account to Wallet", headerColor: Color(hex: "174EA6"))

                if isLoading {
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blueH))
                            .scaleEffect(1.5)
                        
                        Text("Traitement en cours...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Title Card
                            
                          
                            
                            // Account Selection Card
                            accountSelectionCard
                            
                            // Amount Card
                            amountCard
                            
                      
                            // Reference Card
                            referenceCard
                            
                            // Submit Button
                            submitButton
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AppBottomBar(onSponsors: {}, onQR: {}, onLimits: {}, onSettings: {})
        }
        .navigationBarHidden(true)
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showSuccessDialog) {
            AccountToWalletSuccessView(
                transactionId: transactionId,
                transactionDate: transactionDate,
                amount: transactionAmount,
                sourceAccountNumber: selectedAccount?.accountNumber ?? "",
                sourceAccountHolder: accountNameVerified.isEmpty ? (selectedAccount?.accountHolder ?? "") : accountNameVerified,
                sourceBankName: selectedAccount?.bankName ?? "",
                recipientName: userDataManager.getUserName(),
                recipientWallet: userDataManager.getWalletNumber(),
                recipientPhone: userDataManager.getPhoneNumber(),
                withdrawalFee: isWithdrawalFeeEnabled ? withdrawalFee : 0.0,
                fee: calculatedFee,
                total: totalAmountWithFee,
                currency: defaultCurrency,
                paymentDetails: transactionReference,
                onClose: {
                    showSuccessDialog = false
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .sheet(isPresented: $showLinkedAccounts) {
            SavedLinkedAccountsView(accounts: linkedAccounts) { account in
                selectAccount(account)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .overlay(confirmationDialogOverlay)
        .onAppear {
            fetchLinkedAccounts()
        }
    }
    
    private var confirmationDialogOverlay: some View {
        Group {
            if showConfirmationDialog {
                AccountToWalletConfirmationDialog(
                    amount: amount,
                    fee: calculatedFee,
                    withdrawalFee: isWithdrawalFeeEnabled ? withdrawalFee : 0.0,
                    total: totalAmountWithFee,
                    currency: defaultCurrency,
                    accountNumber: selectedAccount?.accountNumber ?? "",
                    accountHolder: selectedAccount?.accountHolder ?? "",
                    paymentDetails: reference,
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
    
    
    // MARK: - Title Card
    private var titleCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blueH)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            VStack(spacing: 8) {
                Text("Transfert de Compte vers Portefeuille")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Rectangle()
                    .fill(.white)
                    .frame(width: 80, height: 3)
            }
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Account Selection Card
    private var accountSelectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Compte Source")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.blueH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            HStack(spacing: 10) {
                Button { showLinkedAccounts = true } label: {
                    HStack {
                        Text(selectedAccount?.accountNumber ?? "Sélectionner un compte")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedAccount == nil ? .secondary : .primary)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "0788B9"))
                    }
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 48)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "505A69"), lineWidth: 1.2))
                }

                Button { showLinkedAccounts = true } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 21))
                            .frame(width: 46, height: 48)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "0788B9"), lineWidth: 1.2))
                        Text("Enregistrés").font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(Color(hex: "0788B9"))
                }
                .disabled(isVerifying)
            }
            
            // Account Holder Name
            TextField("Titulaire du compte", text: .constant(accountNameVerified))
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                .cornerRadius(8)
                .disabled(true)
            
            if isVerifying {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Vérification en cours...")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Amount Card
    private var amountCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Montant")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.blueH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            TextField("Entrer le montant (GMD)", text: $amount)
                .keyboardType(.decimalPad)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                .cornerRadius(8)
                .onChange(of: amount) {
                    calculateTransferFee()
                }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func calculateTransferFee(completion: ((Bool) -> Void)? = nil) {
        let quoteID = UUID()
        feeQuoteID = quoteID
        calculatedFee = 0
        totalAmountWithFee = 0
        withdrawalFee = 0
        isWithdrawalFeeEnabled = false
        guard let account = selectedAccount,
              let value = Double(getCleanAmount(amount)), value.isFinite, value > 0 else {
            isCalculatingTransferFee = false
            completion?(false)
            return
        }
        isCalculatingTransferFee = true
        let bank = userDataManager.getBankCode().isEmpty ? "00100" : userDataManager.getBankCode()
        let request = WalletFeeQuoteRequest(
            walletNumber: userDataManager.getWalletNumber(),
            phoneNumber: userDataManager.getPhoneNumber(), source: "W", bank: bank,
            currency: "270", amount: getCleanAmount(amount), destination: userDataManager.getWalletNumber(),
            transactionType: "45", destinationBank: bank,
            requestId: DateFormatter.with(format: "yyMMdd").string(from: Date()) + String(format: "%06d", Int.random(in: 0...999999)),
            requestDate: DateFormatter.with(format: "yyyy-MM-dd HH:mm:ss").string(from: Date()),
            entityId: userDataManager.getUserCode())
        APIClient.shared.calculateWalletFee(request: request) { result in
            DispatchQueue.main.async {
                guard self.feeQuoteID == quoteID,
                      self.selectedAccount?.accountNumber == account.accountNumber else { return }
                self.isCalculatingTransferFee = false
                switch result {
                case .success(let response):
                    guard response.respCode == "000", let quote = response.result,
                          let fee = quote.feeAmount, fee.isFinite, fee >= 0 else {
                        if completion != nil { self.showErrorAlert(response.message ?? "Unable to calculate fees.") }
                        completion?(false)
                        return
                    }
                    let tax = quote.taxAmount ?? 0
                    let total = quote.totalAmount ?? (value + fee + tax)
                    guard tax.isFinite, tax >= 0, total.isFinite, total >= value else {
                        if completion != nil { self.showErrorAlert("Invalid fee quote. Please try again.") }
                        completion?(false)
                        return
                    }
                    self.calculatedFee = fee + tax
                    self.totalAmountWithFee = total
                    completion?(true)
                case .failure(let error):
                    if completion != nil { self.showErrorAlert((error as? APIError)?.message ?? error.localizedDescription) }
                    completion?(false)
                }
            }
        }
    }

    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "fr_FR")
        return (formatter.string(from: NSNumber(value: amount)) ?? "0") + " " + defaultCurrency
    }
    
    // MARK: - Reference Card
    private var referenceCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Référence (optionnel)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.blueH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            TextField("Entrer une référence", text: $reference)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                .cornerRadius(8)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Submit Button
    private var submitButton: some View {
        VStack(spacing: 16) {
            Button(action: {
                validateAndShowConfirmation()
            }) {
                Text("Soumettre")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 150, height: 48)
                    .background(Color.blueH)
                    .cornerRadius(8)
            }
            .disabled(isLoading || isCalculatingTransferFee || selectedAccount == nil)
        }
        .padding(16)
    }
    
    // MARK: - Helper Methods
    private func fetchLinkedAccounts() {
        isLoading = true
        var request = RequestListLinkedAcc()
        request.source = "W"
        request.walletNumber = userDataManager.getWalletNumber()
        request.phoneNumber = userDataManager.getPhoneNumber()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyMMdd"
        request.requestId = dateFormatter.string(from: Date()) + String(format: "%06d", Int.random(in: 0...999999))

        let fullDateFormatter = DateFormatter()
        fullDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        request.requestDate = fullDateFormatter.string(from: Date())
        request.bank = userDataManager.getBankCode().isEmpty ? "00100" : userDataManager.getBankCode()
        request.entityId = userDataManager.getUserCode()

        APIClient.shared.getLinkedAccounts(request: request) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let response):
                    if response.respCode == "000" {
                        parseLinkedAccounts(response)
                    } else {
                        showErrorAlert("Erreur: \(response.message ?? "Erreur lors de la récupération des comptes")")
                    }
                case .failure(let error):
                    showErrorAlert((error as? APIError)?.message ?? "Erreur réseau: \(error.localizedDescription)")
                }
            }
        }
    }

    private func parseLinkedAccounts(_ response: JResponseService) {
        linkedAccounts.removeAll()
        selectedAccount = nil
        accountNameVerified = ""
        feeQuoteID = UUID()
        isCalculatingTransferFee = false
        calculatedFee = 0
        totalAmountWithFee = 0

        for accountData in response.result ?? [] {
            guard let dict = accountData as? [String: Any] else { continue }
            var account = Account()
            account.accountNumber = dict["accountNumber"] as? String ?? ""
            account.accountHolder = dict["accountHolder"] as? String ?? ""
            account.bankCode = dict["bankCode"] as? String ?? ""
            account.bankName = dict["bankWording"] as? String ?? ""
            account.accountType = dict["accountType"] as? String ?? ""
            account.currency = dict["currency"] as? String ?? ""
            account.balance = dict["balance"] as? String ?? ""
            if !account.accountNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                linkedAccounts.append(account)
            }
        }

        if linkedAccounts.isEmpty {
            showErrorAlert("No linked bank accounts were returned. Link a bank account before transferring to your wallet.")
        }
    }

    private func selectAccount(_ account: Account) {
        selectedAccount = account
        accountNameVerified = ""
        verifyAccount(account)
        // Recalculate transfer fee when account changes
        calculateTransferFee()
    }
    
    private func verifyAccount(_ account: Account) {
        guard !account.accountNumber.isEmpty else { return }
        
        isVerifying = true
        
        var request = RequestWalletToBankAccountNE()
        request.walletNumber = userDataManager.getWalletNumber()
        request.phoneNumber = userDataManager.getPhoneNumber()
        request.source = "W"
        request.desBank = account.bankCode.isEmpty ? "00100" : account.bankCode
        request.srcBank = "00100"
        request.desAccount = account.accountNumber
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyMMdd"
        let datePrefix = dateFormatter.string(from: Date())
        let randomDigits = String(format: "%06d", Int.random(in: 0...999999))
        request.requestId = datePrefix + randomDigits
        
        let fullDateFormatter = DateFormatter()
        fullDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        request.requestDate = fullDateFormatter.string(from: Date())
        request.entityId = UserDataManager.shared.getUserCode()
        
        APIClient.shared.getAccountNameEnquiry(request: request) { result in
            DispatchQueue.main.async {
                self.isVerifying = false
                
                switch result {
                case .success(let response):
                    if response.respCode == "000" {
                        if let result = response.result,
                           let nameToCredit = result["accountHolder"] as? String {
                            self.accountNameVerified = nameToCredit
                            self.selectedAccount?.accountName = nameToCredit
                        } else {
                            self.accountNameVerified = account.accountHolder
                        }
                    } else {
                        self.accountNameVerified = account.accountHolder
                    }
                case .failure:
                    self.accountNameVerified = account.accountHolder
                }
            }
        }
    }
    
    private func validateAndShowConfirmation() {
        guard selectedAccount != nil else {
            showErrorAlert("Veuillez sélectionner un compte")
            return
        }
        
        guard !amount.isEmpty else {
            showErrorAlert("Le montant est requis")
            return
        }
        
        guard let value = Double(getCleanAmount(amount)), value.isFinite, value > 0 else {
            showErrorAlert("Enter a valid amount greater than zero.")
            return
        }
        guard !isCalculatingTransferFee else { return }
        calculateTransferFee { success in
            if success { self.showConfirmationDialog = true }
        }
    }
    
    private func processTransfer(with pinCode: String) {
        guard !isLoading, let account = selectedAccount, !account.accountNumber.isEmpty,
              let value = Double(getCleanAmount(amount)), value.isFinite, value > 0 else { return }
        isLoading = true

        let cleanAmount = getCleanAmount(amount)
        transactionAmount = cleanAmount
        transactionReference = reference
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        transactionDate = dateFormatter.string(from: Date())
        
        var request = RequestAccountToWallet()
        request.walletNumber = userDataManager.getWalletNumber()
        request.phoneNumber = userDataManager.getPhoneNumber()
        request.source = "W"
        request.srcAccount = selectedAccount?.accountNumber
        request.srcBank = account.bankCode.isEmpty ? "00100" : account.bankCode
        request.accountHolder = accountNameVerified.isEmpty ? account.accountHolder : accountNameVerified
        request.desBank = userDataManager.getBankCode().isEmpty ? "00100" : userDataManager.getBankCode()
        request.amount = cleanAmount
        request.otp = ""
        request.pin = pinCode
        request.reason = reference
        request.currency = numericCurrency
        
        let idDateFormatter = DateFormatter()
        idDateFormatter.dateFormat = "yyMMdd"
        let datePrefix = idDateFormatter.string(from: Date())
        let randomDigits = String(format: "%06d", Int.random(in: 0...999999))
        let requestId = String((datePrefix + randomDigits).prefix(12))
        request.requestId = requestId
        
        let fullDateFormatter = DateFormatter()
        fullDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        request.requestDate = fullDateFormatter.string(from: Date())
        request.entityId = UserDataManager.shared.getUserCode()
        
        APIClient.shared.accountToWallet(request: request) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.respCode == "000" {
                        if let reference = response.resultString, !reference.isEmpty {
                            self.transactionId = reference
                        } else if let result = response.result {
                            self.transactionId = result["transactionId"] as? String ??
                                               result["reference"] as? String ??
                                               requestId
                        } else {
                            self.transactionId = response.requestId ?? requestId
                        }
                        
                        self.showSuccessDialog = true
                    } else {
                        self.showErrorAlert("Transfert échoué: \(response.message ?? "Erreur inconnue")")
                    }
                case .failure(let error):
                    if let apiError = error as? APIError {
                        self.showErrorAlert("Erreur: \(apiError.message)")
                    } else {
                        self.showErrorAlert("Erreur réseau: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func getCleanAmount(_ value: String) -> String {
        return value.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: ",", with: ".")
    }
    
    private func showErrorAlert(_ message: String) {
        alertTitle = "Erreur"
        alertMessage = message
        showAlert = true
    }
}

// MARK: - Extension for String cleaning
extension String {
    func cleanCurrencyValue() -> String {
        return self.replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
}

struct AccountToWalletConfirmationDialog: View {
    let amount: String
    let fee: Double
    let withdrawalFee: Double
    let total: Double
    let currency: String
    let accountNumber: String
    let accountHolder: String
    let paymentDetails: String
    
    @Binding var isPresented: Bool
    let onConfirm: (String) -> Void
    let onCancel: () -> Void
    
    @State private var pin: String = ""
    @State private var showPinError = false
    @State private var pinErrorMessage = ""
    @State private var isVerifyingPin = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Confirmer le Transfert")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)
                .padding(.horizontal, 20)
                
                Divider()
                    .padding(.vertical, 16)
                
                // Transaction Details
                ScrollView {
                    VStack(spacing: 16) {
                        // Amount Section with Fees Breakdown
                        VStack(spacing: 12) {
                            DetailRowView(label: "Montant", value: formatAmount(Double(amount.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: ",", with: ".")) ?? 0.0))
                            
                            Divider()
                                .padding(.vertical, 4)
                            
                            // Fees Breakdown Section
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Frais applicables")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                                
                                // Withdrawal Fee (if applicable)
                                if withdrawalFee > 0 {
                                    HStack {
                                        HStack(spacing: 6) {
                                            Image(systemName: "banknote")
                                                .font(.system(size: 12))
                                                .foregroundColor(.orange)
                                            Text("Frais de retrait")
                                                .font(.system(size: 13))
                                                .foregroundColor(.primary)
                                        }
                                        Spacer()
                                        Text(formatAmount(withdrawalFee))
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.orange)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                
                                // Transfer Fee
                                if fee > 0 {
                                    HStack {
                                        HStack(spacing: 6) {
                                            Image(systemName: "paperplane.fill")
                                                .font(.system(size: 12))
                                                .foregroundColor(.blueH)
                                            Text("Frais de transfert")
                                                .font(.system(size: 13))
                                                .foregroundColor(.primary)
                                        }
                                        Spacer()
                                        Text(formatAmount(fee))
                                            .font(.system(size: 13, weight: .semibold))
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
                                                .font(.system(size: 12))
                                                .foregroundColor(.green)
                                            Text("Frais de transfert")
                                                .font(.system(size: 13))
                                                .foregroundColor(.primary)
                                        }
                                        Spacer()
                                        Text("Gratuit")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.green)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                            
                            Divider()
                                .padding(.vertical, 4)
                            
                            DetailRowView(
                                label: "Total à créditer",
                                value: formatAmount(total),
                                isHighlighted: true
                            )
                        }
                        .padding(16)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(12)
                        
                        // Account Source Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Compte source")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            DetailRowView(label: "Compte", value: accountNumber)
                            DetailRowView(label: "Titulaire", value: accountHolder)
                        }
                        .padding(16)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(12)
                        
                        // Payment Details
                        if !paymentDetails.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Référence")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                                
                                Text(paymentDetails)
                                    .font(.system(size: 14))
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(12)
                        }
                        
                        // PIN Entry
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Code PIN")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            SecureField("Entrer le code PIN", text: $pin)
                                .keyboardType(.numberPad)
                                .font(.system(size: 16, weight: .medium))
                                .padding(.horizontal, 16)
                                .frame(height: 50)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(showPinError ? Color.red : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .onChange(of: pin) { newValue in
                                    if newValue.count > 4 { pin = String(newValue.prefix(4)) }
                                    showPinError = false
                                }
                            
                            if showPinError {
                                Text(pinErrorMessage)
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(16)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                }
                .frame(maxHeight: 400)
                
                Divider()
                    .padding(.vertical, 16)
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button(action: {
                        onCancel()
                    }) {
                        Text("Annuler")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blueH)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blueH, lineWidth: 1)
                            )
                    }
                    
                    Button(action: { validateAndConfirm() }) {
                        Group {
                            if isVerifyingPin {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Confirmer")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blueH)
                        .cornerRadius(8)
                    }
                    .disabled(isVerifyingPin)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: 500)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 20)
        }
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "fr_FR")
        return (formatter.string(from: NSNumber(value: amount)) ?? "0") + " " + currency
    }
    
    private func validateAndConfirm() {
        showPinError = false
        
        guard pin.count == 4 else {
            pinErrorMessage = "Le PIN doit contenir exactement 4 chiffres"
            showPinError = true
            return
        }
        
        isVerifyingPin = true
        
        PinVerificationService.verify(pin: pin) { verifiedPin in
            isVerifyingPin = false
            onConfirm(verifiedPin)
        } onFailure: { message in
            isVerifyingPin = false
            pinErrorMessage = message
            showPinError = true
            pin = ""
        }
    }
}

struct AccountToWalletTransferView_Previews: PreviewProvider {
    static var previews: some View {
        AccountToWalletTransferView()
    }
}
