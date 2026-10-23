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
    @State private var selectedFrequencyIndex = 0 // Daily, matching Android
    @State private var destBank = ""
    @State private var destination = ""
    @State private var receiverName = ""
    @State private var amount = ""
    @State private var details = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(365 * 24 * 60 * 60) // 1 year
    
    @State private var showContacts = false
    @State private var showSaved = false
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
    private let defaultCurrency = "GMD"
    private let numericCurrency = "270"
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                StandingInstructionHeader(title: standingText("New standing instruction", "Nouvelle instruction permanente")) {
                    presentationMode.wrappedValue.dismiss()
                }

                if isLoading {
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: StandingInstructionStyle.blue))
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
                        .padding(.top, 17)
                        .padding(.bottom, 18)
                    }
                }
            }
        }
        .tint(StandingInstructionStyle.blue)
        .preferredColorScheme(.light)
        .navigationBarHidden(true)
        .alert(alertTitle, isPresented: $showAlert) {
            Button(AppStrings.ok, role: .cancel) { }
        } message: {
            Text(AppStrings.option(alertMessage))
        }
        .sheet(isPresented: $showContacts) {
            ContactPickerView(selectedPhone: $destination, normalizePhone: WalletTransferRecipient.normalize)
        }
        .sheet(isPresented: $showSaved) {
            SavedWalletRecipientsView { beneficiary in
                destination = WalletTransferRecipient.normalize(beneficiary.destination ?? "")
            }
        }
        .overlay(pinDialogOverlay)
    }
    
    private var transactionTypeCard: some View {
        standingCard(AppStrings.typeDeTransaction) {
            Text(AppStrings.option(transactionTypes[selectedTrxTypeIndex].0))
                .font(.system(size: 17))
                .foregroundColor(.black)
                .standingField()
        }
    }

    private var recipientDetailsCard: some View {
        standingCard(AppStrings.detailsDuDestinataire) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Destination").foregroundColor(StandingInstructionStyle.label)
                HStack(alignment: .top, spacing: 8) {
                    HStack {
                        TextField(standingText("Enter recipient phone number", "Numéro du destinataire"), text: $destination)
                            .keyboardType(.phonePad)
                            .onChange(of: destination) {
                                let normalized = WalletTransferRecipient.normalize(destination)
                                if destination != normalized { destination = normalized; return }
                                resetVerificationFields()
                            }
                        if isVerifying { ProgressView() }
                    }
                    .standingField()
                    .task(id: destination) {
                        guard !destination.isEmpty else { return }
                        do { try await Task.sleep(nanoseconds: 600_000_000) } catch { return }
                        verifyRecipient()
                    }
                    recipientButton(AppStrings.contacts, icon: "person.crop.rectangle.fill") { showContacts = true }
                    recipientButton(AppStrings.saved, icon: "book.closed.fill") { showSaved = true }
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                Text(standingText("Beneficiary Name", "Nom du bénéficiaire")).foregroundColor(StandingInstructionStyle.label)
                Text(receiverName.isEmpty ? standingText("Beneficiary Name", "Nom du bénéficiaire") : receiverName)
                    .foregroundColor(Color(hex: "555F6D"))
                    .standingField()
            }
        }
    }

    private func recipientButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 25, weight: .semibold))
                    .frame(width: 50, height: 50)
                    .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color(hex: "0086B5"), lineWidth: 1))
                Text(title).font(.system(size: 11))
            }
            .foregroundColor(title == AppStrings.saved ? StandingInstructionStyle.blue : StandingInstructionStyle.accent)
        }
        .accessibilityLabel(title)
    }

    private var amountCard: some View {
        standingCard(AppStrings.montant3) {
            VStack(alignment: .leading, spacing: 10) {
                Text(AppStrings.montant3).foregroundColor(StandingInstructionStyle.label)
                TextField(standingText("Amount to Transfer", "Montant à transférer"), text: $amount)
                    .keyboardType(.decimalPad)
                    .standingField()
            }
            .padding(.bottom, 14)
        }
    }

    private var descriptionCard: some View {
        standingCard(AppStrings.description2) {
            TextField(standingText("Payment Details", "Détails du paiement"), text: $details)
                .standingField()
        }
    }

    private var scheduleCard: some View {
        standingCard(AppStrings.frequence) {
            VStack(alignment: .leading, spacing: 10) {
                Text(AppStrings.frequence).foregroundColor(StandingInstructionStyle.label)
                Menu {
                    ForEach(0..<frequencies.count, id: \.self) { index in
                        Button(AppStrings.option(frequencies[index].0)) { selectedFrequencyIndex = index }
                    }
                } label: {
                    Text(AppStrings.option(frequencies[selectedFrequencyIndex].0))
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.black)
                        .standingField()
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                Text(AppStrings.dateDeDebut).foregroundColor(StandingInstructionStyle.label)
                dateButton(startDate) { showStartDatePicker = true }
                    .sheet(isPresented: $showStartDatePicker) {
                        DatePickerSheetA(selectedDate: $startDate, title: AppStrings.dateDeDebut)
                    }
            }
            VStack(alignment: .leading, spacing: 10) {
                Text(AppStrings.dateDeFin).foregroundColor(StandingInstructionStyle.label)
                dateButton(endDate) { showEndDatePicker = true }
                    .sheet(isPresented: $showEndDatePicker) {
                        DatePickerSheetA(selectedDate: $endDate, title: AppStrings.dateDeFin)
                    }
            }
        }
    }

    private func dateButton(_ date: Date, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(formatDateForAPI(date)).foregroundColor(StandingInstructionStyle.label)
                Spacer()
                Image(systemName: "calendar").font(.system(size: 21, weight: .bold)).foregroundColor(StandingInstructionStyle.accent)
            }
            .standingField()
        }
    }

    private var submitButton: some View {
        Button(action: validateAndShowPin) {
            Text(standingText("Create Instruction", "Créer l’instruction"))
                .font(.system(size: 18, weight: .semibold))
                .tracking(1.5)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .frame(height: 50)
                .background(Color(hex: "174EA6"))
                .cornerRadius(9)
                .shadow(color: .black.opacity(0.15), radius: 2, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(isLoading || isVerifying)
        .padding(.vertical, 18)
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
        isVerifying = false
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
        guard WalletTransferRecipient.isValid(destination) else {
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
        let requestedDestination = destination
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
                guard self.destination == requestedDestination else { return }
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
        
        guard let value = Decimal(string: amount.replacingOccurrences(of: ",", with: ".")), value > 0 else {
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
            amount: amount.replacingOccurrences(of: ",", with: "."),
            currency: numericCurrency,
            details: details,
            pin: pin,
            frequency: frequency,
            startDate: formatDateForAPI(startDate),
            endDate: formatDateForAPI(endDate),
            requestId: generateRequestId(),
            requestDate: generateRequestDate(),
            entityId: userDataManager.getUserCode()
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
                            .foregroundColor(StandingInstructionStyle.blue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(StandingInstructionStyle.blue.opacity(0.1))
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
                            .background(StandingInstructionStyle.blue)
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
