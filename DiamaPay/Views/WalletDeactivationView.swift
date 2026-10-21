//
//  WalletDeactivationView.swift
//  DiamaPay
//
//  Created by Bits on 1/10/2025.
//  Updated: Auto-verify recipient on 9 digits and UI optimizations
//

import SwiftUI

struct WalletDeactivationView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - State Variables
    @State private var selectedReasonIndex = 0
    @State private var customReason = ""
    @State private var selectedPaymentMethod: PaymentMethod? = nil
    
    @State private var navigateToLogin = false
    
    // Wallet transfer
    @State private var receiverPhone = ""
    @State private var walletHolderName = ""
    @State private var verifiedWalletHolder = ""
    @State private var destinationBank = ""
    @State private var isRecipientVerified = false
    
    // Account transfer
    @State private var linkedAccounts: [Account] = []
    @State private var selectedAccount: Account? = nil
    @State private var accountHolderName = ""
    
    // Branch transfer
    @State private var branches: [Branch] = []
    @State private var selectedBranch: Branch? = nil
    
    // PIN
    @State private var pin = ""
    @State private var showPin = false
    
    // UI State
    @State private var isLoading = false
    @State private var isVerifying = false
    @State private var showAlert = false
    @State private var alertTitle = "Erreur"
    @State private var alertMessage = ""
    @State private var showConfirmationDialog = false
    @State private var showOtpDialog = false
    @State private var otpCode = ""
    @State private var showSuccessDialog = false
    
    // Deactivation auth code for OTP verification
    @State private var deactivationAuthCode = ""
    
    private let userDataManager = UserDataManager.shared
    private let deactivationReasons = [
        "Sélectionner une raison",
        "Je n'utilise plus le service",
        "Problèmes de sécurité",
        "Interface difficile à utiliser",
        "Frais trop élevés",
        "Service client insatisfaisant",
        "Changement de situation financière",
        "Autre raison"
    ]
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                DiamaPayHeader(title: "Deactivate Wallet", headerColor: Color(hex: "174EA6"))

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
                            headerCard
                            reasonCard
                            paymentMethodCard
                            
                            if selectedPaymentMethod != nil {
                                transferDetailsCard
                                pinCard
                            }
                            
                            warningCard
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
        .overlay(confirmationDialogOverlay)
        .overlay(otpDialogOverlay)
        .overlay(successDialogOverlay)
        .background(
            NavigationLink(
                destination: LoginView()
                    .navigationBarHidden(true),
                isActive: $navigateToLogin,
                label: { EmptyView() }
            )
        )
    }
    
    private var headerCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blueH)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            VStack(spacing: 8) {
                Text("Désactivation du Portefeuille")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Rectangle()
                    .fill(.white)
                    .frame(width: 80, height: 3)
                
                Text("Fermez définitivement votre portefeuille et transférez votre solde")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Reason Card
    private var reasonCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Raison de la Désactivation")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.blueH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            Text("Sélectionnez la raison principale")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Menu {
                ForEach(0..<deactivationReasons.count, id: \.self) { index in
                    Button(deactivationReasons[index]) {
                        selectedReasonIndex = index
                    }
                }
            } label: {
                HStack {
                    Text(deactivationReasons[selectedReasonIndex])
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                .cornerRadius(8)
            }
            
            if selectedReasonIndex == deactivationReasons.count - 1 {
                TextField("Détails supplémentaires (max 50 caractères)", text: $customReason, axis: .vertical)
                    .font(.system(size: 14, weight: .medium))
                    .padding(12)
                    .frame(height: 100, alignment: .top)
                    .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                    .cornerRadius(8)
                    .onChange(of: customReason) {
                        if customReason.count > 50 {
                            customReason = String(customReason.prefix(50))
                        }
                    }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Payment Method Card
    private var paymentMethodCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Méthode de Transfert du Solde")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.blueH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            Text("Choisissez comment recevoir votre solde restant")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            VStack(spacing: 1) {
                paymentMethodButton(.account, title: "Compte bancaire")
                paymentMethodButton(.wallet, title: "Autre portefeuille mobile")
                paymentMethodButton(.branch, title: "Retrait en agence")
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func paymentMethodButton(_ method: PaymentMethod, title: String) -> some View {
        Button(action: {
            selectedPaymentMethod = method
            resetTransferDetails()
            
            switch method {
            case .account:
                loadLinkedAccounts()
            case .branch:
                loadBranches()
            case .wallet:
                break
            }
        }) {
            HStack {
                Image(systemName: selectedPaymentMethod == method ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selectedPaymentMethod == method ? .blueH : .gray)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(height: 48)
            .cornerRadius(8)
        }
    }
    
    // MARK: - Transfer Details Card
    private var transferDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Détails du Destinataire")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.blueH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            if selectedPaymentMethod == .wallet {
                walletTransferSection
            } else if selectedPaymentMethod == .account {
                accountTransferSection
            } else if selectedPaymentMethod == .branch {
                branchTransferSection
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Wallet Transfer Section (Optimized with Auto-Verify)
    private var walletTransferSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Numéro de téléphone du destinataire")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                TextField("Numéro de téléphone", text: $receiverPhone)
                    .keyboardType(.numberPad)
                    .font(.system(size: 14, weight: .medium))
                    .padding(.leading, 12)
                    .onChange(of: receiverPhone) {
                        // Limit to 9 digits
                        if receiverPhone.count > 9 {
                            receiverPhone = String(receiverPhone.prefix(9))
                        }
                        
                        // Auto-verify when 9 digits are entered
                        if receiverPhone.count == 9 {
                            verifyWalletRecipient()
                        } else if receiverPhone.count < 9 {
                            // Reset recipient info if digits are deleted
                            resetWalletVerificationFields()
                        }
                    }
                
                if isVerifying {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blueH))
                        .scaleEffect(0.8)
                        .padding(.trailing, 12)
                } else if isRecipientVerified && !walletHolderName.isEmpty && receiverPhone.count == 9 {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blueH)
                        .padding(.trailing, 12)
                }
            }
            .frame(height: 48)
            .background(Color(red: 0.96, green: 0.96, blue: 0.96))
            .cornerRadius(8)
            
            if isRecipientVerified && !walletHolderName.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nom du titulaire")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "person.fill")
                            .foregroundColor(.blueH)
                            .font(.system(size: 14))
                        
                        Text(walletHolderName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(Color.blueH.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private var accountTransferSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Compte bancaire lié")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            
            if linkedAccounts.isEmpty {
                HStack {
                    Text("Chargement des comptes...")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(height: 48)
                .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                .cornerRadius(8)
            } else {
                Menu {
                    ForEach(linkedAccounts, id: \.accountNumber) { account in
                        Button("\(account.accountNumber) - \(account.accountHolder)") {
                            selectedAccount = account
                            accountHolderName = account.accountHolder
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedAccount != nil ? "\(selectedAccount!.accountNumber) - \(selectedAccount!.accountHolder)" : "Sélectionner un compte")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 48)
                    .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                    .cornerRadius(8)
                    .contentShape(Rectangle())
                }
            }
            
            if !accountHolderName.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nom du titulaire du compte")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text(accountHolderName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 48)
                    .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private var branchTransferSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Agence de retrait")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            
            if branches.isEmpty {
                HStack {
                    Text("Chargement des agences...")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(height: 48)
                .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                .cornerRadius(8)
            } else {
                Menu {
                    ForEach(branches, id: \.id) { branch in
                        Button("\(branch.id ?? "") - \(branch.name ?? "")") {
                            selectedBranch = branch
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedBranch != nil ? "\(selectedBranch!.id ?? "") - \(selectedBranch!.name ?? "")" : "Sélectionner une agence")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 48)
                    .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                    .cornerRadius(8)
                    .contentShape(Rectangle())
                }
            }
            
            Text("💡 Vous pourrez retirer votre solde directement en agence avec une pièce d'identité")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - PIN Card
    private var pinCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Confirmation de Sécurité")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.red)
            
            Text("Entrez votre code PIN pour confirmer la désactivation définitive de votre portefeuille")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            HStack {
                if showPin {
                    TextField("Code PIN", text: $pin)
                        .keyboardType(.numberPad)
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 12)
                        .frame(height: 48)
                        .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                        .cornerRadius(8)
                        .onChange(of: pin) {
                            if pin.count > 4 {
                                pin = String(pin.prefix(4))
                            }
                        }
                } else {
                    SecureField("Code PIN", text: $pin)
                        .keyboardType(.numberPad)
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 12)
                        .frame(height: 48)
                        .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                        .cornerRadius(8)
                        .onChange(of: pin) {
                            if pin.count > 4 {
                                pin = String(pin.prefix(4))
                            }
                        }
                }
                
                Button(action: {
                    showPin.toggle()
                }) {
                    Image(systemName: showPin ? "eye.slash" : "eye")
                        .foregroundColor(.blueH)
                        .padding(.trailing, 12)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Warning Card
    private var warningCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Informations Importantes")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(red: 230/255, green: 81/255, blue: 0/255))
            
            VStack(alignment: .leading, spacing: 4) {
                warningText("• Le solde restant sera transféré vers le destinataire choisi")
                warningText("• Votre portefeuille sera définitivement fermé")
                warningText("• Cette action ne peut pas être annulée")
                warningText("• Vous devrez créer un nouveau compte pour utiliser nos services")
                warningText("• Un code OTP sera envoyé pour confirmation finale")
            }
        }
        .padding(16)
        .background(Color(red: 255/255, green: 243/255, blue: 224/255))
        .cornerRadius(12)
    }
    
    private func warningText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundColor(Color(red: 230/255, green: 81/255, blue: 0/255))
    }
    
    // MARK: - Submit Button
    private var submitButton: some View {
        Button(action: validateAndShowConfirmation) {
            Text("Désactiver le Portefeuille")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.red)
                .cornerRadius(8)
        }
        .disabled(isLoading)
        .padding(.vertical, 20)
    }
    
    // MARK: - Dialog Overlays
    private var confirmationDialogOverlay: some View {
        Group {
            if showConfirmationDialog {
                DeactivationConfirmationDialog(
                    isPresented: $showConfirmationDialog,
                    onConfirm: {
                        showConfirmationDialog = false
                        processDeactivation()
                    },
                    onCancel: {
                        showConfirmationDialog = false
                    }
                )
            }
        }
    }
    
    private var otpDialogOverlay: some View {
        Group {
            if showOtpDialog {
                OtpVerificationDialog(
                    otpCode: $otpCode,
                    isPresented: $showOtpDialog,
                    onVerify: {
                        verifyOtp(otpCode)
                    },
                    onCancel: {
                        showOtpDialog = false
                    }
                )
            }
        }
    }
    
    private var successDialogOverlay: some View {
        Group {
            if showSuccessDialog {
                DeactivationSuccessDialog(
                    isPresented: $showSuccessDialog,
                    navigateToLogin: $navigateToLogin
                )
            }
        }
    }

    // MARK: - Helper Methods
    private func resetTransferDetails() {
        receiverPhone = ""
        walletHolderName = ""
        verifiedWalletHolder = ""
        destinationBank = ""
        isRecipientVerified = false
        selectedAccount = nil
        accountHolderName = ""
        selectedBranch = nil
    }
    
    private func resetWalletVerificationFields() {
        walletHolderName = ""
        verifiedWalletHolder = ""
        destinationBank = ""
        isRecipientVerified = false
    }
    
    private func verifyWalletRecipient() {
        guard receiverPhone.count == 9 else {
            return
        }
        
        isVerifying = true
        
        var request = RequestNameEnquiry()
        request.source = "P"
        request.phoneNumber = receiverPhone
        request.bank = "00100"
        request.pin = userDataManager.getPinForAPI()
        
        let randomLong = UInt64.random(in: 0...UInt64.max)
        let requestIdNumber = randomLong % 1000000000000
        request.requestId = String(format: "%012llu", requestIdNumber)
        
        let fullDateFormatter = DateFormatter()
        fullDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        request.requestDate = fullDateFormatter.string(from: Date())
        request.entityId = UserDataManager.shared.getUserCode()
        
        APIClient.shared.getWalletInfo(request: request) { result in
            DispatchQueue.main.async {
                self.isVerifying = false
                
                switch result {
                case .success(let response):
                    if response.respCode == "000" {
                        self.handleVerificationSuccess(response)
                    } else {
                        self.handleVerificationError(response)
                    }
                case .failure(let error):
                    if let apiError = error as? APIError {
                        self.showErrorAlert("Erreur: \(apiError.message)")
                    } else {
                        self.showErrorAlert("Erreur réseau: \(error.localizedDescription)")
                    }
                    self.resetWalletVerificationFields()
                }
            }
        }
    }
    
    private func handleVerificationSuccess(_ response: ResponseServiceJson) {
        if let result = response.result {
            let clientName = result["walletHolder"] as? String ?? ""
            let phoneConfirmed = result["phoneNumber"] as? String ?? ""
            
            let phoneSuffix = String(phoneConfirmed.suffix(9))
            if !receiverPhone.hasSuffix(phoneSuffix) && receiverPhone != phoneConfirmed {
                showErrorAlert("Le numéro vérifié ne correspond pas au numéro saisi")
                resetWalletVerificationFields()
                return
            }
            
            destinationBank = "00100"
            verifiedWalletHolder = clientName
            walletHolderName = clientName
            isRecipientVerified = true
        } else {
            showErrorAlert("Information du destinataire non disponible")
            resetWalletVerificationFields()
        }
    }
    
    private func handleVerificationError(_ response: ResponseServiceJson) {
        let errorMessage = response.message ?? {
            switch response.respCode {
            case "001": return "Portefeuille non trouvé"
            case "003": return "Données manquantes dans la requête"
            case "005": return "Code PIN incorrect"
            case "006": return "Code PIN bloqué"
            case "021": return "Utilisateur non autorisé"
            default: return "Échec de la vérification. Code: \(response.respCode ?? "N/A")"
            }
        }()
        
        showErrorAlert(errorMessage)
        resetWalletVerificationFields()
    }
    
    private func loadLinkedAccounts() {
        isLoading = true
        
        var request = RequestListLinkedAcc()
        request.source = "W"
        request.walletNumber = userDataManager.getWalletNumber()
        request.phoneNumber = userDataManager.getPhoneNumber()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyMMdd"
        let datePrefix = dateFormatter.string(from: Date())
        let randomDigits = String(format: "%06d", Int.random(in: 0...999999))
        request.requestId = datePrefix + randomDigits
        
        let fullDateFormatter = DateFormatter()
        fullDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        request.requestDate = fullDateFormatter.string(from: Date())
        
        let bankCode = userDataManager.getBankCode().isEmpty ? "00100" : userDataManager.getBankCode()
        request.bank = bankCode
        request.entityId = UserDataManager.shared.getUserCode()
        
        APIClient.shared.getLinkedAccounts(request: request) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.respCode == "000" {
                        self.parseLinkedAccounts(response)
                    } else {
                        self.showErrorAlert("Erreur: \(response.message ?? "Impossible de charger les comptes")")
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
                account.accountName = dict["accountName"] as? String ?? ""
                account.bankCode = dict["bankCode"] as? String ?? ""
                account.bankName = dict["bankName"] as? String ?? ""
                account.accountType = dict["accountType"] as? String ?? ""
                account.currency = dict["currency"] as? String ?? ""
                account.balance = dict["balance"] as? String ?? ""
                
                linkedAccounts.append(account)
            }
        }
        
        if linkedAccounts.isEmpty {
            showErrorAlert("Aucun compte bancaire lié trouvé")
        }
    }
    
    private func loadBranches() {
        isLoading = true
        
        let bankCode = userDataManager.getBankCode().isEmpty ? "00100" : userDataManager.getBankCode()
        
        APIClient.shared.getAllBranches(bankCode: bankCode) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let branchList):
                    self.branches = branchList
                    if self.branches.isEmpty {
                        self.showErrorAlert("Aucune agence trouvée")
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
    
    private func validateAndShowConfirmation() {
        if selectedReasonIndex == 0 {
            showErrorAlert("Veuillez sélectionner une raison de désactivation")
            return
        }
        
        if selectedReasonIndex == deactivationReasons.count - 1 && customReason.trimmingCharacters(in: .whitespaces).isEmpty {
            showErrorAlert("Veuillez préciser la raison de désactivation")
            return
        }
        
        guard let paymentMethod = selectedPaymentMethod else {
            showErrorAlert("Veuillez sélectionner une méthode de transfert")
            return
        }
        
        switch paymentMethod {
        case .wallet:
            if receiverPhone.trimmingCharacters(in: .whitespaces).isEmpty {
                showErrorAlert("Veuillez saisir le numéro du destinataire")
                return
            }
            if !isRecipientVerified || verifiedWalletHolder.isEmpty {
                showErrorAlert("Veuillez d'abord vérifier le destinataire")
                return
            }
        case .account:
            if selectedAccount == nil {
                showErrorAlert("Veuillez sélectionner un compte")
                return
            }
        case .branch:
            if selectedBranch == nil {
                showErrorAlert("Veuillez sélectionner une agence")
                return
            }
        }
        
        if pin.trimmingCharacters(in: .whitespaces).isEmpty {
            showErrorAlert("Veuillez saisir votre code PIN")
            return
        }
        
        if pin.count < 4 {
            showErrorAlert("Le code PIN doit contenir au moins 4 chiffres")
            return
        }
        
        showConfirmationDialog = true
    }
    
    private func processDeactivation() {
        //print("=== STARTING WALLET DEACTIVATION PROCESS ===")
        isLoading = true
        
        var request = RequestDeactivateWallet()
        request.source = "P"
        let phoneNumber = userDataManager.getPhoneNumber()
        request.phoneNumber = phoneNumber
        //print("Source: P, Phone Number: \(phoneNumber)")
        
        request.pin = pin
        //print("PIN length: \(pin.count)")
        
        let reason = selectedReasonIndex == deactivationReasons.count - 1
            ? customReason.trimmingCharacters(in: .whitespaces)
            : deactivationReasons[selectedReasonIndex]
        request.reason = reason
        //print("Reason: \(reason)")
        
        guard let paymentMethod = selectedPaymentMethod else { return }
        
        switch paymentMethod {
        case .wallet:
            request.paymentMethod = "W"
            request.receiver = receiverPhone
            request.beneficiaryName = verifiedWalletHolder
            request.institution = destinationBank
            //print("Wallet transfer - Receiver: \(receiverPhone), Beneficiary: \(verifiedWalletHolder), Institution: \(destinationBank)")
            
        case .account:
            request.paymentMethod = "A"
            request.receiver = selectedAccount?.accountNumber ?? ""
            request.beneficiaryName = selectedAccount?.accountHolder ?? ""
            request.institution = selectedAccount?.bankCode ?? ""
            //print("Account transfer - Account: \(request.receiver), Holder: \(request.beneficiaryName), Bank: \(request.institution)")
            
        case .branch:
            request.paymentMethod = "B"
            let branchId = selectedBranch?.id ?? ""
            let branchName = selectedBranch?.name ?? ""
            request.receiver = branchId
            request.beneficiaryName = "Branch Cash Out - \(branchName)"
            let userBankCode = userDataManager.getBankCode().isEmpty ? "00100" : userDataManager.getBankCode()
            request.institution = userBankCode
            //print("Branch transfer - Branch ID: \(branchId), Branch Name: \(branchName), Institution: \(userBankCode)")
        }
        
        request.walletNumber = userDataManager.getPhoneNumber()
        //print("Wallet Number: \(request.walletNumber)")
     
        let randomLong = UInt64.random(in: 0...UInt64.max)
        let requestIdNumber = randomLong % 1000000000000
        request.requestId = String(format: "%012llu", requestIdNumber)
        //print("Generated Request ID: \(request.requestId)")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        request.requestDate = dateFormatter.string(from: Date())
        //print("Request Date: \(request.requestDate)")
        
        request.entityId = userDataManager.getUserCode()
        //print("Entity ID: \(request.entityId)")
        
        //print("=== SENDING DEACTIVATION REQUEST ===")
        
        APIClient.shared.deactivateWallet(request: request) { result in
            DispatchQueue.main.async {
                //print("=== DEACTIVATION RESPONSE RECEIVED ===")
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    //print("Response Status: \(response.status ?? "nil")")
                    //print("Response Code: \(response.respCode ?? "nil")")
                    //print("Response Message: \(response.message ?? "nil")")
                    //print("Response Auth Code: \(response.authCode ?? "nil")")
                    
                    if response.respCode == "000" {
                        self.deactivationAuthCode = response.authCode ?? ""
                        //print("Deactivation request successful")
                        
                        if let message = response.message, message.contains("OTP") {
                            //print("OTP verification required - showing OTP dialog")
                            self.showOtpDialog = true
                        } else {
                            //print("No OTP required - showing success dialog")
                            self.showSuccessDialog = true
                        }
                    } else {
                        //print("Deactivation request failed with code: \(response.respCode ?? "nil")")
                        let errorMsg = response.message ?? "Erreur lors de la désactivation du portefeuille"
                        self.showErrorAlert(errorMsg)
                    }
                    
                case .failure(let error):
                    //print("=== DEACTIVATION REQUEST FAILED ===")
                    if let apiError = error as? APIError {
                        //print("Error: \(apiError.message)")
                        self.showErrorAlert("Erreur: \(apiError.message)")
                    } else {
                        //print("Network error: \(error.localizedDescription)")
                        self.showErrorAlert("Erreur réseau: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func verifyOtp(_ otp: String) {
        //print("=== STARTING OTP VERIFICATION ===")
        //print("OTP: \(otp)")
        //print("AuthCode: \(deactivationAuthCode)")
        
        guard !otp.trimmingCharacters(in: .whitespaces).isEmpty else {
            showErrorAlert("Veuillez saisir le code OTP")
            return
        }
        
        guard otp.count == 6 else {
            showErrorAlert("Le code OTP doit contenir exactement 6 chiffres")
            return
        }
        
        isLoading = true
        
        let phoneNumber = userDataManager.getPhoneNumber()
        let entityId = userDataManager.getUserCode()
        
        let request = OtpRequest(
            phoneNumber: phoneNumber,
            authCode: deactivationAuthCode,
            otp: otp,
            entityId: entityId
        )
        APIClient.shared.verifyOtp(request: request) { result in
            DispatchQueue.main.async {
                //print("=== OTP VERIFICATION RESPONSE RECEIVED ===")
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    //print("Response Status: \(response.status ?? "nil")")
                    //print("Response Code: \(response.respCode ?? "nil")")
                    //print("Response Message: \(response.message ?? "nil")")
                    
                    if response.respCode == "000" || response.isSuccessful {
                        //print("OTP verification successful")
                        self.showOtpDialog = false
                        self.showSuccessDialog = true
                    } else {
                        //print("OTP verification failed: \(response.respCode ?? "nil")")
                        let errorMsg = response.message ?? "Code OTP invalide. Veuillez réessayer."
                        self.showErrorAlert(errorMsg)
                    }
                    
                case .failure(let error):
                    //print("=== OTP VERIFICATION REQUEST FAILED ===")
                    if let apiError = error as? APIError {
                        //print("Error: \(apiError.message)")
                        self.showErrorAlert("Erreur: \(apiError.message)")
                    } else {
                        //print("Network error: \(error.localizedDescription)")
                        self.showErrorAlert("Erreur réseau: \(error.localizedDescription)")
                    }
                }
            }
        }
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

// MARK: - Payment Method Enum
enum PaymentMethod {
    case account
    case wallet
    case branch
}

// MARK: - Deactivation Confirmation Dialog
struct DeactivationConfirmationDialog: View {
    @Binding var isPresented: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }
            
            VStack(spacing: 20) {
                Text("Confirmation de Désactivation")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Êtes-vous sûr de vouloir désactiver définitivement votre portefeuille ?\n\nCette action est irréversible et votre compte sera fermé.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                HStack(spacing: 12) {
                    Button(action: onCancel) {
                        Text("Annuler")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.blueH)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.blueH.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Button(action: onConfirm) {
                        Text("Oui, Désactiver")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(radius: 20)
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - OTP Verification Dialog
struct OtpVerificationDialog: View {
    @Binding var otpCode: String
    @Binding var isPresented: Bool
    let onVerify: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }
            
            VStack(spacing: 20) {
                Text("Vérification OTP")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Un code de vérification a été envoyé à votre numéro. Veuillez saisir le code pour confirmer la désactivation.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                TextField("Code OTP", text: $otpCode)
                    .keyboardType(.numberPad)
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 12)
                    .frame(height: 48)
                    .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .onChange(of: otpCode) {
                        if otpCode.count > 6 {
                            otpCode = String(otpCode.prefix(6))
                        }
                    }
                
                HStack(spacing: 12) {
                    Button(action: onCancel) {
                        Text("Annuler")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.blueH)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.blueH.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        guard !otpCode.trimmingCharacters(in: .whitespaces).isEmpty else {
                            return
                        }
                        onVerify()
                    }) {
                        Text("Vérifier")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.blueH)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(radius: 20)
            .padding(.horizontal, 40)
        }
    }
}

struct DeactivationSuccessDialog: View {
    @Binding var isPresented: Bool
    @Binding var navigateToLogin: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("Demande Envoyée")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("""
                Votre demande de désactivation a été transmise avec succès.

                Le solde restant sera transféré selon vos instructions.

                Merci d'avoir utilisé nos services.
                """)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                
                Button(action: {
                    closeAndNavigate()
                }) {
                    Text("Fermer")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.blueH)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
            }
            .padding(32)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(radius: 20)
            .padding(.horizontal, 40)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                closeAndNavigate()
            }
        }
    }
    
    private func closeAndNavigate() {
        if isPresented {
            isPresented = false
            navigateToLogin = true
        }
    }
}

// MARK: - Preview
struct WalletDeactivationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WalletDeactivationView()
        }
    }
}
