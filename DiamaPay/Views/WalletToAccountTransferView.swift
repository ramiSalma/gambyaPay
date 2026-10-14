//
//  WalletToAccountTransferView.swift
//  DiamaPay
//
//  Created by Bits on 30/9/2025.
//


//
//  WalletToAccountTransferView.swift
//  DiamaPay
//
//  Created by Bits on 30/9/2025.
//

import SwiftUI

struct WalletToAccountTransferView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedSource: SourceOfFunds = .wallet
    @State private var selectedWallet: SponsoringWallet?
    
    // MARK: - State Variables
    @State private var linkedAccounts: [Account] = []
    @State private var selectedAccount: Account?
    @State private var accountName: String = ""
    @State private var amount: String = ""
    @State private var paymentDetails: String = ""
    
    @State private var isLoadingAccounts = false
    @State private var isVerifying = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Erreur"
    
    // Transfer management
    @State private var calculatedFee: Double = 0.0
    @State private var totalAmountWithFee: Double = 0.0
    @State private var feeRuleIndex = ""
    @State private var nameEnquiryAuthCode: String = ""
    
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
                DiamaPayHeader(title: "Wallet to Account", headerColor: Color(hex: "174EA6"))

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
                        VStack(spacing: 20) {
                            // Balance Display
                            SourceOfFundsView(
                                onSourceChanged: { source in
                                    selectedSource = source
                                },
                                onWalletChanged: { wallet in
                                    selectedWallet = wallet
                                },
                                walletTransferStyle: true
                            )
                            
                            // Recipient Details Card
                            recipientDetailsCard
                            
                            // Amount Card
                            amountCard

                            // Reference Card
                            referenceCard
                            
                            // Submit Button
                            submitButton
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 22)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            WalletTransferBottomBar()
        }
        .navigationBarHidden(true)
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showSuccessDialog) {
            AccountTransferSuccessView(
                transactionId: transactionId,
                transactionDate: transactionDate,
                amount: amount,
                accountName: accountName,
                accountNumber: selectedAccount?.accountNumber ?? "",
                bankName: selectedAccount?.bankName ?? "",
                senderName: userDataManager.getUserName(),
                senderWallet: userDataManager.getWalletNumber(),
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
        .onAppear {
            fetchLinkedAccounts()
        }
    }
    

    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "fr_FR")
        return (formatter.string(from: NSNumber(value: amount)) ?? "0") + " " + defaultCurrency
    }
    
    
    private var confirmationDialogOverlay: some View {
        Group {
            if showConfirmationDialog {
                AccountTransferConfirmationDialog(
                    amount: amount,
                    fee: calculatedFee,
                    total: totalAmountWithFee,
                    currency: defaultCurrency,
                    accountName: accountName,
                    accountNumber: selectedAccount?.accountNumber ?? "",
                    bankName: selectedAccount?.bankName ?? "",
                    paymentDetails: paymentDetails,
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
    

    // MARK: - Recipient Details Card
    private var recipientDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Account Details")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "174EA6"))
                
                Rectangle()
                    .fill(Color(hex: "0788B9"))
                    .frame(width: 110, height: 3)
            }
            
            HStack(alignment: .top, spacing: 10) {
                HStack {
                    Text(selectedAccount?.accountNumber ?? "Enter account number")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "505A69"))
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "505A69"), lineWidth: 1.5))

                VStack(spacing: 5) {
                    Button {
                        if let selectedAccount { verifyAccount(selectedAccount) }
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(Color(hex: "0788B9"))
                            .frame(width: 44, height: 44)
                            .background(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "0788B9"), lineWidth: 1.5))
                    }
                    .disabled(selectedAccount == nil || isVerifying)
                    Text("Verify").font(.system(size: 14, weight: .medium)).foregroundColor(Color(hex: "0788B9"))
                }

                VStack(spacing: 5) {
                    Menu {
                        ForEach(linkedAccounts) { account in
                            Button(account.displayName) {
                                selectedAccount = account
                                verifyAccount(account)
                            }
                        }
                    } label: {
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 23, weight: .semibold))
                            .foregroundColor(Color(hex: "174EA6"))
                            .frame(width: 44, height: 44)
                            .background(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "0788B9"), lineWidth: 1.5))
                    }
                    .disabled(isLoadingAccounts || linkedAccounts.isEmpty)
                    Text("Saved").font(.system(size: 14, weight: .medium)).foregroundColor(Color(hex: "174EA6"))
                }
            }
            
            // Account name display
            TextField("Beneficiary Name", text: .constant(accountName))
                .font(.system(size: 16, weight: .medium))
                .padding(.horizontal, 16)
                .frame(height: 48)
                .background(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "505A69"), lineWidth: 1.5))
                .disabled(true)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 5)
    }
    // MARK: - Amount Card
    private var amountCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Amount")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "174EA6"))
                
                Rectangle()
                    .fill(Color(hex: "0788B9"))
                    .frame(width: 110, height: 3)
            }
            
            // Replace the TextField with FormattedTextField
            FormattedTextField(
                placeholder: "Amount *",
                text: $amount,
                walletTransferStyle: true
            )
                .onChange(of: amount) {
                    NSObject.cancelPreviousPerformRequests(withTarget: self)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.calculateWithdrawalFee()
                    }
                }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 5)
    }
    
    
    private func calculateWithdrawalFeeDebounced() {
        calculateWithdrawalFee()
    }
    
    private func calculateWithdrawalFee() {
        let cleanAmount = amount.cleanCurrencyValue()
        
        guard !cleanAmount.isEmpty,
              let amountValue = Double(cleanAmount),
              amountValue > 0 else {
            withdrawalFee = 0.0
            withdrawalFeeError = nil
            isWithdrawalFeeEnabled = false
            return
        }
        
        isCalculatingWithdrawalFee = true
        withdrawalFeeError = nil
        
        var request = FeeCalculationRequest()
        request.processingCode = "42"
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
                    print("response: \(response)")
                    print("response: \(response.self)")
                    print("response: \(response.message)")
                    print("response: \(response.respCode)")

                    if response.respCode == "000" || response.respCode == "001" {
                        self.withdrawalFee = response.feeAmount ?? 0.0
                        if self.withdrawalFee == 0 {
                            self.isWithdrawalFeeEnabled = false
                        }
                    } else {
                        self.withdrawalFee = 0.0
                        self.isWithdrawalFeeEnabled = false
                        self.withdrawalFeeError = response.message
                    }
                    
                case .failure(_):
                    self.withdrawalFee = 0.0
                    self.isWithdrawalFeeEnabled = false
                    self.withdrawalFeeError = "Impossible de calculer"
                }
            }
        }
    }
    
    // MARK: - Reference Card
    private var referenceCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Reason (optional)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "174EA6"))
                
                Rectangle()
                    .fill(Color(hex: "0788B9"))
                    .frame(width: 110, height: 3)
            }
            
            TextField("Enter a reason", text: $paymentDetails)
                .font(.system(size: 16, weight: .medium))
                .padding(.horizontal, 16)
                .frame(height: 48)
                .background(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "505A69"), lineWidth: 1.5))
                .onReceive(paymentDetails.publisher.collect()) { chars in
                    if chars.count > 25 {
                        paymentDetails = String(chars.prefix(25))
                    }
                }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Submit Button
    private var submitButton: some View {
        VStack(spacing: 16) {
            Button(action: {
                validateAndShowConfirmation()
            }) {
                Text("Submit")
                    .font(.system(size: 18, weight: .bold)).tracking(1.5)
                    .foregroundColor(.white)
                    .frame(width: 130, height: 48)
                    .background(selectedAccount != nil && !accountName.isEmpty && !amount.isEmpty
                                ? Color(hex: "0788B9")
                                : Color(hex: "DCDCDC"))
                    .cornerRadius(12)
            }
            .disabled(isLoading)
        }
        .padding(16)
    }
    
    private func fetchLinkedAccounts() {
        isLoadingAccounts = true
        
        var request = RequestListLinkedAcc()
        request.source = "W"
        request.walletNumber = userDataManager.getWalletNumber()
        request.phoneNumber = userDataManager.getPhoneNumber()
        
        // Generate requestId
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyMMdd"
        let datePrefix = dateFormatter.string(from: Date())
        let randomDigits = String(format: "%06d", Int.random(in: 0...999999))
        request.requestId = datePrefix + randomDigits
        
        let fullDateFormatter = DateFormatter()
        fullDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        request.requestDate = fullDateFormatter.string(from: Date())
        
        request.bank = userDataManager.getBankCode().isEmpty ? "00100" : userDataManager.getBankCode()
        request.entityId = UserDataManager.shared.getUserCode()
        
        APIClient.shared.getLinkedAccounts(request: request) { result in
            DispatchQueue.main.async {
                self.isLoadingAccounts = false
                
                switch result {
                case .success(let response):
                    if response.respCode == "000" || response.respCode == "00" {
                        self.parseLinkedAccounts(response)
                    } else {
                        self.showErrorAlert("Erreur: \(response.message ?? "Impossible de récupérer les comptes")")
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
    
    private func parseLinkedAccounts(_ response: JResponseService) {
        linkedAccounts.removeAll()
        
        if let resultList = response.result {
            for accountData in resultList {
                guard let dict = accountData as? [String: Any] else { continue }
                
                var account = Account()
                account.accountNumber = dict["accountNumber"] as? String ?? ""
                account.accountHolder = dict["accountHolder"] as? String ?? ""
                account.bankCode = dict["bankCode"] as? String ?? ""
                account.bankName = dict["bankName"] as? String ?? ""
                account.accountType = dict["accountType"] as? String ?? ""
                account.currency = dict["currency"] as? String ?? ""
                account.balance = dict["balance"] as? String ?? ""
                
                if !account.accountNumber.isEmpty {
                    linkedAccounts.append(account)
                }
            }
        }
        
        if linkedAccounts.isEmpty {
            showErrorAlert("Aucun compte bancaire lié trouvé")
        }
    }
    
    private func verifyAccount(_ account: Account) {
        guard !account.accountNumber.isEmpty else {
            showErrorAlert("Numéro de compte invalide")
            return
        }
        
        isVerifying = true
        accountName = ""
        
        var request = RequestWalletToBankAccountNE()
        request.walletNumber = userDataManager.getWalletNumber()
        request.source = "W"
        request.desBank = account.bankCode.isEmpty ? "00100" : account.bankCode
        request.srcBank = "00100"
        request.desAccount = account.accountNumber
        
        // Generate requestId
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyMMdd"
        let datePrefix = dateFormatter.string(from: Date())
        let randomDigits = String(format: "%06d", Int.random(in: 0...999999))
        request.requestId = datePrefix + randomDigits
        
        let fullDateFormatter = DateFormatter()
        fullDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        request.requestDate = fullDateFormatter.string(from: Date())
        request.entityId = UserDataManager.shared.getUserCode()
        
        APIClient.shared.transferWalletToAccountNE(request: request) { result in
            DispatchQueue.main.async {
                self.isVerifying = false
                
                switch result {
                case .success(let response):
                    if response.respCode == "000" || response.respCode == "00" {
                        self.handleVerificationSuccess(response, account: account)
                    } else {
                        self.handleVerificationError(response)
                    }
                case .failure(let error):
                    if let apiError = error as? APIError {
                        self.showErrorAlert("Erreur: \(apiError.message)")
                    } else {
                        self.showErrorAlert("Erreur réseau: \(error.localizedDescription)")
                    }
                    self.accountName = ""
                }
            }
        }
    }
    
    private func handleVerificationSuccess(_ response: ResponseServiceJson, account: Account) {
        if let result = response.result {
            if let nameToCredit = result["NameToCredit"] as? String {
                accountName = nameToCredit
                nameEnquiryAuthCode = response.authCode ?? ""
                showSuccessAlert("Compte vérifié avec succès")
            } else {
                accountName = account.accountHolder.isEmpty ? account.accountName : account.accountHolder
                nameEnquiryAuthCode = response.authCode ?? ""
                showSuccessAlert("Compte vérifié")
            }
        } else {
            showErrorAlert("Information du compte non disponible")
            accountName = ""
        }
    }
    
    private func handleVerificationError(_ response: ResponseServiceJson) {
        let errorMessage = response.message ?? {
            switch response.respCode {
            case "001": return "Compte non trouvé"
            case "003": return "Données manquantes dans la requête"
            default: return "Échec de la vérification. Code: \(response.respCode ?? "N/A")"
            }
        }()
        
        showErrorAlert(errorMessage)
        accountName = ""
    }
    
    private func validateAndShowConfirmation() {
        guard validateInputs() else { return }
        calculateTransactionFee()
    }
    
    private func validateInputs() -> Bool {
        if selectedSource == .sponsor && selectedWallet == nil {
            showErrorAlert("Please select a sponsor wallet")
            return false
        }

        if selectedAccount == nil {
            showErrorAlert("Veuillez sélectionner un compte")
            return false
        }
        
        if amount.isEmpty {
            showErrorAlert("Le montant est requis")
            return false
        }
        
        if accountName.isEmpty {
            showErrorAlert("Veuillez d'abord vérifier le compte")
            return false
        }
        
        return true
    }
    
    private func calculateTransactionFee() {
        isLoading = true
        
        var feeRequest = FeeCalculationRequest()
        feeRequest.processingCode = selectedSource == .wallet ? "42" : "10" // Wallet to Account
        feeRequest.bankCode = selectedAccount?.bankCode ?? "00100"
        feeRequest.actionCode = "DEB"
        feeRequest.currencyCode = "324"
        feeRequest.transactionAmount = Double(amount.cleanCurrencyValue().replacingOccurrences(of: ",", with: ".")) ?? 0.0
        feeRequest.walletProductCode = "001"
        feeRequest.walletType = "P"
        feeRequest.origin = "W"
        
        APIClient.shared.calculateTransactionFee(request: feeRequest) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.respCode == "000" {
                        self.calculatedFee = response.feeAmount ?? 0.0
                        self.totalAmountWithFee = (Double(self.amount.cleanCurrencyValue().replacingOccurrences(of: ",", with: ".")) ?? 0.0) + self.calculatedFee
                        self.feeRuleIndex = response.ruleIndex ?? ""
                    } else {
                        self.calculatedFee = 0.0
                        self.totalAmountWithFee = Double(self.amount.replacingOccurrences(of: ",", with: ".")) ?? 0.0
                    }
                case .failure(_):
                    self.calculatedFee = 0.0
                    self.totalAmountWithFee = Double(self.amount.replacingOccurrences(of: ",", with: ".")) ?? 0.0
                }
                
                self.showConfirmationDialog = true
            }
        }
    }
    
    private func processTransfer(with pinCode: String) {
        isLoading = true
        
        var request = RequestWalletToAccount()
        request.walletNumber = userDataManager.getWalletNumber()
        request.phoneNumber = userDataManager.getPhoneNumber()
        request.source = "W"
        request.srcBank = "00100"
        request.desAccount = selectedAccount?.accountNumber ?? ""
        request.desBank = selectedAccount?.bankCode ?? "00100"
        let baseAmount = Double(amount.cleanCurrencyValue()) ?? 0.0
        let withdrawalFeeValue = isWithdrawalFeeEnabled ? withdrawalFee : 0.0
        let finalAmount = baseAmount + withdrawalFeeValue
        request.amount = String(finalAmount)
        request.currency = numericCurrency
        request.reason = String(paymentDetails.prefix(25))
        request.pin = pinCode
        request.authCode = nameEnquiryAuthCode
        if selectedSource == .sponsor {
            request.sponsorWallet = selectedWallet?.walletNumber
        }
        
        // Generate request ID
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
        
        APIClient.shared.transferWalletToAccount(request: request) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.respCode == "000" {
                        self.handleTransferSuccess(response, requestId: requestId)
                    }else {
                        self.showError(message: "Transfert échoué: \(response.message ?? "Erreur inconnue")")
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
    
    private func handleTransferSuccess(_ response: ResponseServiceJson, requestId: String) {
        if let result = response.result {
            transactionId = result["transactionId"] as? String ?? 
                           result["reference"] as? String ?? 
                           requestId
        } else {
            transactionId = requestId
        }
        
        transactionReference = transactionId
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        transactionDate = dateFormatter.string(from: Date())
        
        showSuccessDialog = true
    }
    private func showError(message: String) {
        alertTitle = "Erreur"
        alertMessage = message
        showAlert = true
    }
    private func showErrorAlert(_ message: String) {
        alertTitle = "Erreur"
        alertMessage = message
        showAlert = true
    }
    
    private func showSuccessAlert(_ message: String) {
        alertTitle = "Succès"
        alertMessage = message
        showAlert = true
    }
}

private struct WalletTransferBottomBar: View {
    var body: some View {
        ZStack(alignment: .top) {
            HStack {
                item("house.fill", "Home", selected: true)
                Spacer()
                item("hand.thumbsup", "Sponsors", selected: false)
                Spacer(minLength: 54)
                item("speedometer", "Limits", selected: false)
                Spacer()
                item("gearshape.fill", "Settings", selected: false)
            }
            .padding(.horizontal, 22)
            .padding(.top, 25)
            .padding(.bottom, 8)
            .background(WalletBottomBarShape().fill(Color(hex: "174EA6")).ignoresSafeArea(edges: .bottom))

            Image(systemName: "qrcode")
                .font(.system(size: 29, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 78, height: 78)
                .background(Color(hex: "0788B9"))
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 6))
                .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                .offset(y: -31)
        }
        .frame(height: 82)
    }

    private func item(_ icon: String, _ title: String, selected: Bool) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 22, weight: .semibold))
            Text(title).font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(selected ? .white : Color.white.opacity(0.48))
        .frame(minWidth: 52)
    }
}

private struct WalletBottomBarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 30
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.maxY))
        path.addLine(to: CGPoint(x: 0, y: radius))
        path.addQuadCurve(to: CGPoint(x: radius, y: 0), control: .zero)
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: 0))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: radius), control: CGPoint(x: rect.maxX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

