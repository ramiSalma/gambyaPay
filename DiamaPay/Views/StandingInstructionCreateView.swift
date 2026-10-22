//
//  StandingInstructionCreateView.swift
//  DiamaPay
//
//  Created by Bits on 1/10/2025.
//

import SwiftUI

struct StandingInstructionCreateView: View {
    @ObservedObject private var localization = AppLanguageStore.shared
    @Environment(\.presentationMode) var presentationMode
    
    let onSuccess: () -> Void
    
    // MARK: - Transaction Types
    private let transactionTypes = [
        (AppStrings.original("portefeuilleVersPortefeuille"), "41")
    ]
    
    private let frequencies = [
        (AppStrings.original("quotidien"), "D"),
        (AppStrings.original("hebdomadaire"), "W"),
        (AppStrings.original("mensuel"), "M"),
        (AppStrings.original("annuel"), "Y")
    ]
    
    // MARK: - State Variables
    @State private var selectedTrxTypeIndex = 0
    @State private var selectedFrequencyIndex = 2 // Default to Monthly
    @State private var destBank = ""
    @State private var destination = ""
    @State private var receiverName = ""
    @State private var amount = ""
    @State private var details = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(365 * 24 * 60 * 60) // 1 year
    
    @State private var showStartDatePicker = false
    @State private var showEndDatePicker = false
    @State private var isVerifying = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = AppStrings.information
    @State private var showPinDialog = false
    @State private var isRecipientVerified = false
    
    private let userDataManager = UserDataManager.shared
    private let defaultCurrency = "GNF"
    private let numericCurrency = "324"
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                DiamaPayHeader(title: AppStrings.createStandingInstruction, headerColor: Color(hex: "174EA6"), onBackToHome: {
                    presentationMode.wrappedValue.dismiss()
                })

                if isLoading {
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blueH))
                            .scaleEffect(1.5)
                        
                        Text(AppStrings.traitementEnCours)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Title Card
                            
                            // Transaction Type Card
                            transactionTypeCard
                            
                            // Recipient Details Card
                            recipientDetailsCard
                            
                            // Amount Card
                            amountCard
                            
                            // Description Card
                            descriptionCard
                            
                            // Schedule Card
                            scheduleCard
                            
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
            Button(AppStrings.ok, role: .cancel) { }
        } message: {
            Text(AppStrings.option(alertMessage))
        }
        .overlay(pinDialogOverlay)
    }
    
    // MARK: - Title Card
    private var titleCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blueH)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            VStack(spacing: 8) {
                Text(AppStrings.creerUnVirementPermanent)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Rectangle()
                    .fill(.white)
                    .frame(width: 80, height: 3)
            }
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Transaction Type Card
    private var transactionTypeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(AppStrings.typeDeTransaction)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.blueH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            Menu {
                ForEach(0..<transactionTypes.count, id: \.self) { index in
                    Button(action: {
                        selectedTrxTypeIndex = index
                        updateUIForTransactionType()
                    }) {
                        Text(AppStrings.option(transactionTypes[index].0))
                    }
                }
            } label: {
                HStack {
                    Text(AppStrings.option(transactionTypes[selectedTrxTypeIndex].0))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Recipient Details Card (Optimized with Auto-Verify)
    private var recipientDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(AppStrings.detailsDuDestinataire)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.blueH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            // Bank Code (only for wallet to account)
            if transactionTypes[selectedTrxTypeIndex].1 == "42" {
                TextField(AppStrings.codeBanque, text: $destBank)
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 12)
                    .frame(height: 48)
                    .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                    .cornerRadius(8)
            }
            
            // Destination with auto-verify
            HStack(spacing: 8) {
                TextField(getDestinationPlaceholder(), text: $destination)
                    .keyboardType(.numberPad)
                    .font(.system(size: 14, weight: .medium))
                    .padding(.leading, 12)
                    .onChange(of: destination) {
                        // Limit to 9 digits
                        if destination.count > 9 {
                            destination = String(destination.prefix(9))
                        }
                        
                        // Auto-verify when 9 digits are entered
                        if destination.count == 9 {
                            verifyRecipient()
                        } else if destination.count < 9 {
                            // Reset recipient info if digits are deleted
                            resetVerificationFields()
                        }
                    }
                
                if isVerifying {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blueH))
                        .scaleEffect(0.8)
                        .padding(.trailing, 12)
                } else if isRecipientVerified && !receiverName.isEmpty && destination.count == 9 {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blueH)
                        .padding(.trailing, 12)
                }
            }
            .frame(height: 48)
            .background(Color(red: 0.96, green: 0.96, blue: 0.96))
            .cornerRadius(8)
            
            // Receiver Name (only show when verified)
            if isRecipientVerified && !receiverName.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "person.fill")
                        .foregroundColor(.blueH)
                        .font(.system(size: 14))
                    
                    Text(receiverName)
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
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Amount Card
    private var amountCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(AppStrings.montant3)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.blueH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            FormattedTextField(placeholder: AppStrings.entrerLeMontantGnf, text: $amount)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Description Card
    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(AppStrings.description2)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.blueH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            TextField(AppStrings.entrerUneDescription, text: $details)
                .font(.system(size: 14, weight: .medium))
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
    
    // MARK: - Schedule Card
    private var scheduleCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(AppStrings.planification)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.blueH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            // Frequency
            Menu {
                ForEach(0..<frequencies.count, id: \.self) { index in
                    Button(action: {
                        selectedFrequencyIndex = index
                    }) {
                        Text(AppStrings.option(frequencies[index].0))
                    }
                }
            } label: {
                HStack {
                    Text(AppStrings.option(frequencies[selectedFrequencyIndex].0))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                .cornerRadius(8)
            }
            
            // Start Date
            Button(action: { showStartDatePicker = true }) {
                HStack {
                    Text(AppStrings.dateDeDebut)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatDate(startDate))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Image(systemName: "calendar")
                        .foregroundColor(.blueH)
                }
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                .cornerRadius(8)
            }
            .sheet(isPresented: $showStartDatePicker) {
                DatePickerSheetA(selectedDate: $startDate, title: AppStrings.dateDeDebut)
            }
            
            // End Date
            Button(action: { showEndDatePicker = true }) {
                HStack {
                    Text(AppStrings.dateDeFin)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatDate(endDate))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Image(systemName: "calendar")
                        .foregroundColor(.blueH)
                }
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                .cornerRadius(8)
            }
            .sheet(isPresented: $showEndDatePicker) {
                DatePickerSheetA(selectedDate: $endDate, title: AppStrings.dateDeFin)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Submit Button
    private var submitButton: some View {
        Button(action: validateAndShowPin) {
            Text(AppStrings.creer)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blueH)
                .cornerRadius(8)
        }
        .disabled(isLoading)
        .padding(.vertical, 20)
    }
    
    // MARK: - PIN Dialog Overlay
    private var pinDialogOverlay: some View {
        Group {
            if showPinDialog {
                PinEntryDialog(
                    isPresented: $showPinDialog,
                    onConfirm: { pin in
                        showPinDialog = false
                        createStandingInstruction(with: pin)
                    },
                    onCancel: {
                        showPinDialog = false
                    }
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    private func updateUIForTransactionType() {
        let trxType = transactionTypes[selectedTrxTypeIndex].1
        
        if trxType == "42" {
            destBank = "00100"
        } else {
            destBank = ""
        }
        
        // Reset fields
        destination = ""
        receiverName = ""
        isRecipientVerified = false
    }
    
    private func resetVerificationFields() {
        receiverName = ""
        isRecipientVerified = false
    }
    
    private func getDestinationPlaceholder() -> String {
        let trxType = transactionTypes[selectedTrxTypeIndex].1
        
        switch trxType {
        case "41": return AppStrings.nDeTelephone
        case "42": return AppStrings.nDeCompte
        case "70": return AppStrings.nDeTelephoneMobile
        case "33": return AppStrings.nDeCompteDEpargne
        default: return "Destination"
        }
    }
    
    private func verifyRecipient() {
        guard destination.count == 9 else {
            return
        }
        
        isVerifying = true
        let trxType = transactionTypes[selectedTrxTypeIndex].1
        
        switch trxType {
        case "41":
            verifyWalletToWallet()
        case "42":
            verifyWalletToAccount()
        case "70":
            verifyMobileMoney()
        default:
            isVerifying = false
            showErrorAlert(AppStrings.verificationNonDisponiblePourCeType)
        }
    }
    
    private func verifyWalletToWallet() {
        var request = RequestNameEnquiry()
        request.source = "P"
        request.phoneNumber = destination
        request.bank = "00100"
        request.pin = userDataManager.getPinForAPI()
        request.requestId = generateRequestId()
        request.requestDate = generateRequestDate()
        request.entityId = UserDataManager.shared.getUserCode()
        
        APIClient.shared.getWalletInfo(request: request) { result in
            DispatchQueue.main.async {
                self.isVerifying = false
                
                switch result {
                case .success(let response):
                    if response.respCode == "000", let result = response.result {
                        let walletHolder = result["walletHolder"] as? String ?? ""
                        self.receiverName = walletHolder
                        self.isRecipientVerified = true
                    } else {
                        self.showErrorAlert(AppStrings.erreurValue(String(describing: response.message ?? AppStrings.verificationEchouee)))
                        self.resetVerificationFields()
                    }
                case .failure(let error):
                    if let apiError = error as? APIError {
                        self.showErrorAlert(AppStrings.erreurValue(AppStrings.option(apiError.message)))
                    } else {
                        self.showErrorAlert(AppStrings.erreurReseauValue(String(describing: error.localizedDescription)))
                    }
                    self.resetVerificationFields()
                }
            }
        }
    }
    
    private func verifyWalletToAccount() {
        guard !destBank.isEmpty else {
            isVerifying = false
            showErrorAlert(AppStrings.leCodeBanqueEstRequis)
            return
        }
        
        // Implementation similar to WalletTransferView
        isVerifying = false
        showErrorAlert(AppStrings.verificationDeCompteNonImplementee)
    }
    
    private func verifyMobileMoney() {
        // Implementation for mobile money verification
        isVerifying = false
        showErrorAlert(AppStrings.verificationMobileMoneyNonImplementee)
    }
    
    private func validateAndShowPin() {
        guard !destination.isEmpty else {
            showErrorAlert(AppStrings.laDestinationEstRequise)
            return
        }
        
        guard !amount.isEmpty else {
            showErrorAlert(AppStrings.leMontantEstRequis)
            return
        }
        
        guard isRecipientVerified && !receiverName.isEmpty else {
            showErrorAlert(AppStrings.veuillezDAbordVerifierLeDestinataire)
            return
        }
     
        guard startDate < endDate else {
            showErrorAlert(AppStrings.laDateDeDebutDoitEtreAvantLaDateDe)
            return
        }
        
        guard endDate > Date() else {
            showErrorAlert(AppStrings.laDateDeFinNePeutPasEtreDansLe)
            return
        }
        
        showPinDialog = true
    }
    
    private func createStandingInstruction(with pin: String) {
        isLoading = true
        
        let trxType = transactionTypes[selectedTrxTypeIndex].1
        let frequency = frequencies[selectedFrequencyIndex].1
        
        let request = StandingInstructionDto(
            phoneNumber: userDataManager.getPhoneNumber(),
            trxType: trxType,
            destBank: trxType == "42" ? destBank : "",
            receiver: receiverName,
            destination: destination,
            amount: amount.cleanCurrencyValue(),
            currency: numericCurrency,
            details: details,
            pin: pin,
            frequency: frequency,
            startDate: formatDateForAPI(startDate),
            endDate: formatDateForAPI(endDate),
            requestId: generateRequestId(),
            requestDate: generateRequestDate(),
            entityId: "00100"
        )
        
        APIClient.shared.createStandingInstruction(request: request) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.respCode == "000" {
                        self.showSuccessAlert(AppStrings.virementPermanentCreeAvecSucces)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            self.onSuccess()
                        }
                    } else {
                        self.showErrorAlert(AppStrings.erreurValue(String(describing: response.message ?? AppStrings.echecDeLaCreation)))
                    }
                case .failure(let error):
                    if let apiError = error as? APIError {
                        self.showErrorAlert(AppStrings.erreurValue(AppStrings.option(apiError.message)))
                    } else {
                        self.showErrorAlert(AppStrings.erreurReseauValue(String(describing: error.localizedDescription)))
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
    
    private func formatDateForAPI(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func generateRequestId() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyMMdd"
        let datePrefix = dateFormatter.string(from: Date())
        let randomDigits = String(format: "%06d", Int.random(in: 0...999999))
        return datePrefix + randomDigits
    }
    
    private func generateRequestDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: Date())
    }
    
    private func showErrorAlert(_ message: String) {
        alertTitle = AppStrings.error
        alertMessage = message
        showAlert = true
    }
    
    private func showSuccessAlert(_ message: String) {
        alertTitle = AppStrings.succes
        alertMessage = message
        showAlert = true
    }
}

// MARK: - PIN Entry Dialog
struct PinEntryDialog: View {
    @ObservedObject private var localization = AppLanguageStore.shared
    @Binding var isPresented: Bool
    let onConfirm: (String) -> Void
    let onCancel: () -> Void
    
    @State private var pin = ""
    @State private var showError = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }
            
            VStack(spacing: 0) {
                Text(AppStrings.entrerLeCodePin)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                
                SecureField(AppStrings.pin, text: $pin)
                    .keyboardType(.numberPad)
                    .font(.system(size: 16, weight: .medium))
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .onChange(of: pin) {
                        if pin.count > 4 {
                            pin = String(pin.prefix(4))
                        }
                    }
                
                if showError {
                    Text(AppStrings.veuillezEntrerVotrePin)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                        .padding(.top, 4)
                }
                
                HStack(spacing: 12) {
                    Button(action: onCancel) {
                        Text(AppStrings.annuler)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.blueH)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.blueH.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        if pin.isEmpty {
                            showError = true
                        } else {
                            showError = false
                            onConfirm(pin)
                        }
                    }) {
                        Text(AppStrings.confirmer)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.blueH)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 20)
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Date Picker Sheet
struct DatePickerSheetA: View {
    @ObservedObject private var localization = AppLanguageStore.shared
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedDate: Date
    let title: String
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding()
                
                Spacer()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(AppStrings.termine) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
