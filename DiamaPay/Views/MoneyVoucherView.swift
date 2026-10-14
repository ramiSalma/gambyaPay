//
//  MoneyVoucherView.swift - Updated with Recipient Name & ID
//  DiamaPay
//

import Contacts
import ContactsUI
import SwiftUI

struct MoneyVoucherView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - State Variables
    @State private var selectedSource: SourceOfFunds = .wallet
    @State private var selectedWallet: SponsoringWallet? = nil
    @State private var currentBalance: String = ""
    
    @State private var receiverPhone: String = ""
    @State private var recipientName: String = ""  // Manual entry
    @State private var recipientIdNumber: String = ""  // NEW: ID number field
    @State private var amount: String = ""
    @State private var paymentDetails: String = ""
    
    @State private var showContactPicker = false
    @State private var isVerifying = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Erreur"
    
    // Voucher management
    @State private var calculatedFee: Double = 0.0
    @State private var totalAmountWithFee: Double = 0.0
    @State private var feeRuleIndex = ""
    
    // Withdrawal Fee (NEW)
    @State private var withdrawalFee: Double = 0.0
    @State private var isWithdrawalFeeEnabled: Bool = false
    @State private var isCalculatingWithdrawalFee = false
    @State private var withdrawalFeeError: String? = nil
    
    
    // Success dialog state
    @State private var showSuccessDialog = false
    @State private var transactionId = ""
    @State private var transactionDate = ""
    @State private var transactionReference = ""
    @State private var voucherCode = ""
    
    private let userDataManager = UserDataManager.shared
    private let defaultCurrency = "GNF"
    private let numericCurrency = "324"
    
    @State private var showConfirmationDialog = false
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                DiamaPayHeader()

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
                            titleCard
                            
                            // Source of Funds View
                            SourceOfFundsView(
                                onSourceChanged: { source in
                                    selectedSource = source
                                },
                                onWalletChanged: { wallet in
                                    selectedWallet = wallet
                                },
                                onBalanceChanged: { balance in
                                    currentBalance = balance
                                }
                            )
                            
                            // Recipient Details Card (UPDATED)
                            recipientDetailsCard
                            
                            // Amount Card
                            amountCard
                            
                            withdrawalFeeCard

                            
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
        .navigationBarHidden(true)
        .onDisappear {
            isLoading = false
            isVerifying = false
            showConfirmationDialog = false
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showContactPicker) {
            ContactPickerView(selectedPhone: $receiverPhone)
        }
        .sheet(isPresented: $showSuccessDialog) {
            VoucherSuccessView(
                transactionId: transactionId,
                transactionDate: transactionDate,
                amount: amount,
                recipientName: recipientName,
                recipientPhone: receiverPhone,
                senderName: userDataManager.getUserName(),
                senderPhone: userDataManager.getPhoneNumber(),
                fee: calculatedFee,
                withdrawalFee: isWithdrawalFeeEnabled ? withdrawalFee : 0.0,
                total: totalAmountWithFee,
                currency: defaultCurrency,
                paymentDetails: paymentDetails,
                voucherCode: voucherCode,
                onClose: {
                    showSuccessDialog = false
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .overlay(confirmationDialogOverlay)
    }
    

    
    // MARK: - Title Card
    private var titleCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blueH)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            VStack(spacing: 8) {
                Text("Mise à Disposition")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Rectangle()
                    .fill(.white)
                    .frame(width: 80, height: 3)
            }
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Recipient Details Card (UPDATED WITH NAME & ID)
    private var recipientDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Détails du Destinataire")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.greenH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            // Phone Number with Contact Picker
            HStack(spacing: 8) {
                TextField("N° du destinataire", text: $receiverPhone)
                    .keyboardType(.numberPad)
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 12)
                    .frame(height: 48)
                    .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                    .cornerRadius(8)
                    .onChange(of: receiverPhone) {
                        if receiverPhone.count > 10 {
                            receiverPhone = String(receiverPhone.prefix(10))
                        }
                    }
                
                VStack(spacing: 2) {
                    Button(action: {
                        showContactPicker = true
                    }) {
                        Image(systemName: "person.circle")
                            .font(.system(size: 18))
                            .foregroundColor(.blueH)
                            .frame(width: 50, height: 50)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blueH, lineWidth: 1)
                            )
                            .cornerRadius(8)
                    }
                    
                    Text("Contacts")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.blueH)
                }
            }
            
            // NEW: Recipient Name Field (REQUIRED)
            TextField("Nom du destinataire", text: $recipientName)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                .cornerRadius(8)
                .autocapitalization(.words)
            
            // NEW: ID Number Field (REQUIRED)
            TextField("N° pièce d'identité", text: $recipientIdNumber)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                .cornerRadius(8)
                .autocapitalization(.none)
                .disableAutocorrection(true)
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
                    .foregroundColor(Color.greenH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            FormattedTextField(placeholder: "Entrer le montant (GNF)", text: $amount, maxLength: 50)
                .onChange(of: amount) {
                NSObject.cancelPreviousPerformRequests(withTarget: self)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.calculateWithdrawalFee()
                }
            }       }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Withdrawal Fee Card (NEW)
    private var withdrawalFeeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ajouter les frais de retrait")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                    
                    if isCalculatingWithdrawalFee {
                        HStack(spacing: 4) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blueH))
                                .scaleEffect(0.7)
                            Text("Calcul...")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    } else if let error = withdrawalFeeError {
                        Text(error)
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                    } else if withdrawalFee > 0 {
                        Text("Frais: \(formatAmount(withdrawalFee))")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    } else if !amount.isEmpty {
                        Text("Aucun frais applicable")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    } else {
                        Text("Entrez un montant pour voir les frais")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Toggle("", isOn: $isWithdrawalFeeEnabled)
                    .labelsHidden()
                    .disabled(withdrawalFee == 0.0 || amount.isEmpty)
            }
        }
        .padding(16)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "fr_FR")
        return (formatter.string(from: NSNumber(value: amount)) ?? "0") + " " + defaultCurrency
    }
    
    private func calculateWithdrawalFeeDebounced() {
        calculateWithdrawalFee()
    }
   
    
    private var referenceCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Commentaire (optionnel)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.greenH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            TextField("Entrer un commentaire", text: $paymentDetails)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                .cornerRadius(8)
                .onChange(of: paymentDetails) {
                    if paymentDetails.count > 50 {
                        paymentDetails = String(paymentDetails.prefix(50))
                    }
                }
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
                    .background(Color.greenH)
                    .cornerRadius(8)
            }
            .disabled(isLoading)
        }
        .padding(16)
    }
    
    // MARK: - Validation (UPDATED)
    private func validateAndShowConfirmation() {
        guard validateInputs() else { return }
        calculateTransactionFee()
    }
    
    private func validateInputs() -> Bool {
        // Source validation
        if selectedSource == .sponsor && selectedWallet == nil {
            showErrorAlert("Veuillez sélectionner un portefeuille sponsor")
            return false
        }
        
        // Sponsor limit validation
        if selectedSource == .sponsor, let wallet = selectedWallet {
            if let requestedAmount = Double(amount.replacingOccurrences(of: ",", with: ".")),
               !wallet.dailyLimit.isEmpty,
               let dailyLimit = Double(wallet.dailyLimit),
               requestedAmount > dailyLimit {
                showErrorAlert("Le montant dépasse la limite quotidienne du sponsor")
                return false
            }
        }
        
        // Phone number validation
        if receiverPhone.isEmpty {
            showErrorAlert("Le numéro de téléphone est requis")
            return false
        }
        
        // NEW: Recipient name validation (REQUIRED)
        if recipientName.trimmingCharacters(in: .whitespaces).isEmpty {
            showErrorAlert("Le nom du destinataire est requis")
            return false
        }
        
        // NEW: ID number validation (REQUIRED)
        if recipientIdNumber.trimmingCharacters(in: .whitespaces).isEmpty {
            showErrorAlert("Le N° de pièce d'identité est requis")
            return false
        }
        
        // Amount validation
        if amount.isEmpty {
            showErrorAlert("Le montant est requis")
            return false
        }
        
        return true
    }
    
  
 
    private func handleVoucherSuccess(_ response: ResponseService, requestId: String) {
        if let result = response.result {
            switch result {
            case .string(let value):
                let trimmed = value.trimmingCharacters(in: .whitespaces)
                transactionId = trimmed.isEmpty ? requestId : trimmed
                
            case .dictionary(let dict):
                if let txId = dict["transactionId"]?.value as? String {
                    transactionId = txId
                } else if let reference = dict["reference"]?.value as? String {
                    transactionId = reference
                } else {
                    transactionId = requestId
                }
                
            case .array(_):
                transactionId = requestId
            }
        } else if let reqId = response.requestId?.trimmingCharacters(in: .whitespaces), !reqId.isEmpty {
            transactionId = reqId
        } else {
            transactionId = requestId
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        transactionDate = dateFormatter.string(from: Date())
        
        transactionReference = paymentDetails
        
        showSuccessDialog = true
    }
    
    private func showErrorAlert(_ message: String) {
        alertTitle = "Erreur"
        alertMessage = message
        showAlert = true
    }
    
    // MARK: - Fee Calculation (NO DISPATCH QUEUE VERSION)
    private func calculateTransactionFee() {
        isLoading = true
        
        var feeRequest = FeeCalculationRequest()
        feeRequest.processingCode = selectedSource == .sponsor ? "10" : "43"
        feeRequest.bankCode = "00100"
        feeRequest.actionCode = "DEB"
        feeRequest.currencyCode = "324"
        feeRequest.transactionAmount = Double(amount.cleanCurrencyValue().replacingOccurrences(of: ",", with: ".")) ?? 0.0
        feeRequest.walletProductCode = "001"
        feeRequest.walletType = "P"
        feeRequest.origin = "W"
        
        //print("🔵 Starting fee calculation for amount: \(feeRequest.transactionAmount)")
        
        APIClient.shared.calculateTransactionFee(request: feeRequest) { result in
            self.isLoading = false
            
            switch result {
            case .success(let response):
                //print("🔵 API Response Code: \(response.respCode)")
                //print("🔵 Response feeAmount: \(String(describing: response.feeAmount))")
                
                if response.respCode == "000" || response.respCode == "001" {
                    // Get fee from the nested result object
                    let extractedFee = response.result?.feeAmount ?? 0.0
                    /*
                    //print("✅ Fee Amount: \(extractedFee)")
                    //print("✅ Total Amount: \(response.result?.totalAmount ?? 0.0)")
                    */
                    self.calculatedFee = extractedFee
                    self.feeRuleIndex = response.result?.ruleIndex ?? ""
                    
                    // Calculate total with all fees
                    let baseAmount = Double(self.amount.cleanCurrencyValue().replacingOccurrences(of: ",", with: ".")) ?? 0.0
                    let withdrawalFeeValue = self.isWithdrawalFeeEnabled ? self.withdrawalFee : 0.0
                    self.totalAmountWithFee = baseAmount + withdrawalFeeValue + self.calculatedFee
                    
                    //print("📊 Fee Calculation Complete:")
                    //print("   Base Amount: \(baseAmount)")
                    //print("   Withdrawal Fee: \(withdrawalFeeValue)")
                    //print("   Transaction Fee: \(self.calculatedFee)")
                    //print("   Total: \(self.totalAmountWithFee)")
                    
                    // Show dialog
                    //print("🎯 Showing dialog with fee: \(self.calculatedFee), total: \(self.totalAmountWithFee)")
                    self.showConfirmationDialog = true
                    
                } else {
                    // Fee calculation failed
                    self.showErrorAlert("Impossible de calculer les frais: \(response.message ?? "Erreur inconnue")")
                }
                
            case .failure(let error):
                // Network error
                if let apiError = error as? APIError {
                    self.showErrorAlert("Erreur: \(apiError.message)")
                } else {
                    self.showErrorAlert("Erreur réseau lors du calcul des frais")
                }
            }
        }
    }

    // MARK: - Withdrawal Fee Calculation (NO DISPATCH QUEUE VERSION)
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
        request.processingCode = "43"
        request.bankCode = "00100"
        request.actionCode = "CRD"
        request.currencyCode = "324"
        request.transactionAmount = amountValue
        request.walletProductCode = "001"
        request.walletType = "P"
        request.origin = "W"
        request.messageType = "ON_US"
        
        APIClient.shared.calculateWithdrawalFee(request: request) { result in
            self.isCalculatingWithdrawalFee = false
            
            switch result {
            case .success(let response):
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

    // MARK: - Process Voucher (NO DISPATCH QUEUE VERSION)
    private func processMoneyVoucher(with pinCode: String) {
        isLoading = true
        
        var request = RequestMoneyVoucher()
        request.walletNumber = userDataManager.getWalletNumber()
        request.phoneNumber = userDataManager.getPhoneNumber()
        request.source = "W"
        request.bank = "00100"
        request.currency = userDataManager.getCurrency()
        let baseAmount = Double(amount.cleanCurrencyValue()) ?? 0.0
        let withdrawalFeeValue = isWithdrawalFeeEnabled ? withdrawalFee : 0.0
        let finalAmount = baseAmount + withdrawalFeeValue
        request.amount = String(finalAmount)
        request.receiverPhone = receiverPhone
        
        // BUILD REASON FIELD: Name + ID + Optional Comment
        var reasonBuilder = recipientName.trimmingCharacters(in: .whitespaces)
        
        if !recipientIdNumber.trimmingCharacters(in: .whitespaces).isEmpty {
            reasonBuilder += " | ID: " + recipientIdNumber.trimmingCharacters(in: .whitespaces)
        }
        
        if !paymentDetails.trimmingCharacters(in: .whitespaces).isEmpty {
            reasonBuilder += " | " + paymentDetails.trimmingCharacters(in: .whitespaces)
        }
        
        request.reason = String(reasonBuilder.prefix(100))
        request.pin = pinCode
        
        if selectedSource == .sponsor, let wallet = selectedWallet {
            request.sponsorWallet = wallet.walletNumber
        }
        
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
        
        APIClient.shared.moneyVoucher(request: request) { result in
            self.isLoading = false
            
            switch result {
            case .success(let response):
                if response.isSuccessful {
                    self.handleVoucherSuccess(response, requestId: requestId)
                } else {
                    self.showErrorAlert("Mise à disposition échouée: \(response.message ?? "Erreur inconnue")")
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

    // MARK: - Confirmation Dialog Overlay
    private var confirmationDialogOverlay: some View {
        Group {
            if showConfirmationDialog {
                VoucherConfirmationDialog(
                    amount: amount,
                    withdrawalFee: isWithdrawalFeeEnabled ? withdrawalFee : 0.0,
                    fee: calculatedFee,
                    total: totalAmountWithFee,
                    currency: defaultCurrency,
                    recipientName: recipientName.isEmpty ? "Destinataire" : recipientName,
                    recipientPhone: receiverPhone,
                    paymentDetails: paymentDetails,
                    sourceType: selectedSource,
                    selectedWallet: selectedWallet,
                    isPresented: $showConfirmationDialog,
                    onConfirm: { pinCode in
                        showConfirmationDialog = false
                        processMoneyVoucher(with: pinCode)
                    },
                    onCancel: {
                        showConfirmationDialog = false
                    }
                )
                .onAppear {
                    //print("🔍 Dialog appeared with:")
                    //print("   Fee: \(self.calculatedFee)")
                    //print("   Total: \(self.totalAmountWithFee)")
                }
            }
        }
    }
}
