//
//  StandingInstructionCreateView.swift
//  DiamaPay
//
//  Created by Bits on 1/10/2025.
//

import SwiftUI

struct StandingInstructionCreateView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let onSuccess: () -> Void
    
    // MARK: - Transaction Types
    private let transactionTypes = [
        ("Portefeuille vers Portefeuille", "41")
    ]
    
    private let frequencies = [
        ("Quotidien", "D"),
        ("Hebdomadaire", "W"),
        ("Mensuel", "M"),
        ("Annuel", "Y")
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
    @State private var alertTitle = "Information"
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
                DiamaPayHeader(title: "Create Standing Instruction", headerColor: Color(hex: "174EA6"), onBackToHome: {
                    presentationMode.wrappedValue.dismiss()
                })

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
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
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
                Text("Créer un Virement Permanent")
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
                Text("Type de Transaction")
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
                        Text(transactionTypes[index].0)
                    }
                }
            } label: {
                HStack {
                    Text(transactionTypes[selectedTrxTypeIndex].0)
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
                Text("Détails du Destinataire")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.blueH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            // Bank Code (only for wallet to account)
            if transactionTypes[selectedTrxTypeIndex].1 == "42" {
                TextField("Code banque", text: $destBank)
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
                Text("Montant")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.blueH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            FormattedTextField(placeholder: "Entrer le montant (GNF)", text: $amount)
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
                Text("Description")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.blueH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            TextField("Entrer une description", text: $details)
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
                Text("Planification")
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
                        Text(frequencies[index].0)
                    }
                }
            } label: {
                HStack {
                    Text(frequencies[selectedFrequencyIndex].0)
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
                    Text("Date de début")
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
                DatePickerSheetA(selectedDate: $startDate, title: "Date de début")
            }
            
            // End Date
            Button(action: { showEndDatePicker = true }) {
                HStack {
                    Text("Date de fin")
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
                DatePickerSheetA(selectedDate: $endDate, title: "Date de fin")
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
            Text("Créer")
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
        case "41": return "N° de téléphone"
        case "42": return "N° de compte"
        case "70": return "N° de téléphone mobile"
        case "33": return "N° de compte d'épargne"
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
            showErrorAlert("Vérification non disponible pour ce type")
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
                        self.showErrorAlert("Erreur: \(response.message ?? "Vérification échouée")")
                        self.resetVerificationFields()
                    }
                case .failure(let error):
                    if let apiError = error as? APIError {
                        self.showErrorAlert("Erreur: \(apiError.message)")
                    } else {
                        self.showErrorAlert("Erreur réseau: \(error.localizedDescription)")
                    }
                    self.resetVerificationFields()
                }
            }
        }
    }
    
    private func verifyWalletToAccount() {
        guard !destBank.isEmpty else {
            isVerifying = false
            showErrorAlert("Le code banque est requis")
            return
        }
        
        // Implementation similar to WalletTransferView
        isVerifying = false
        showErrorAlert("Vérification de compte non implémentée")
    }
    
    private func verifyMobileMoney() {
        // Implementation for mobile money verification
        isVerifying = false
        showErrorAlert("Vérification mobile money non implémentée")
    }
    
    private func validateAndShowPin() {
        guard !destination.isEmpty else {
            showErrorAlert("La destination est requise")
            return
        }
        
        guard !amount.isEmpty else {
            showErrorAlert("Le montant est requis")
            return
        }
        
        guard isRecipientVerified && !receiverName.isEmpty else {
            showErrorAlert("Veuillez d'abord vérifier le destinataire")
            return
        }
     
        guard startDate < endDate else {
            showErrorAlert("La date de début doit être avant la date de fin")
            return
        }
        
        guard endDate > Date() else {
            showErrorAlert("La date de fin ne peut pas être dans le passé")
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
                        self.showSuccessAlert("Virement permanent créé avec succès")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            self.onSuccess()
                        }
                    } else {
                        self.showErrorAlert("Erreur: \(response.message ?? "Échec de la création")")
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

// MARK: - PIN Entry Dialog
struct PinEntryDialog: View {
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
                Text("Entrer le code PIN")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                
                SecureField("Code PIN", text: $pin)
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
                    Text("Veuillez entrer votre PIN")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                        .padding(.top, 4)
                }
                
                HStack(spacing: 12) {
                    Button(action: onCancel) {
                        Text("Annuler")
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
                        Text("Confirmer")
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
                    Button("Terminé") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
