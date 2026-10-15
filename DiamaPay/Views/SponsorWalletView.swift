//
//  SponsorWalletView.swift
//  DiamaPay
//
//  Created by Bits on 30/9/2025.
//

import SwiftUI
import Contacts
import ContactsUI

struct SponsorWalletView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var navigationPath = NavigationPath()
    
    // MARK: - State Variables
    @State private var recipientPhone: String = ""
    @State private var recipientName: String = ""
    @State private var dailyLimit: String = ""
    @State private var monthlyLimit: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var pin: String = ""
    
    @State private var showContactPicker = false
    @State private var showStartDatePicker = false
    @State private var showEndDatePicker = false
    @State private var showPinEntry = false
    @State private var isVerifying = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    @State private var sponsoredBankCode = ""
    @State private var isRecipientVerified = false
    
    private let userDataManager = UserDataManager.shared
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                DiamaPayHeader(title: "Sponsor a Wallet", headerColor: Color(hex: "174EA6"))

                if isLoading {
                    loadingView
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Title Card
                            
                            // PIN Entry Card (conditionally visible)
                            if showPinEntry {
                                pinEntryCard
                            }
                            
                            // Source Details Card
                            sourceDetailsCard
                            
                            // Recipient Details Card
                            recipientDetailsCard
                            
                            // Limits Card
                            limitsCard
                            
                            // Period Card
                            periodCard
                            
                            // Submit Button
                            submitButton
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .padding(.bottom, 30)
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
        .sheet(isPresented: $showContactPicker) {
            ContactPickerView(selectedPhone: $recipientPhone)
        }
        .sheet(isPresented: $showStartDatePicker) {
            DatePickerSheetz(
                selectedDate: $startDate,
                minimumDate: Date(),
                title: "Date de début",
                onSave: {
                    showStartDatePicker = false
                    validateDateRange()
                }
            )
        }
        .sheet(isPresented: $showEndDatePicker) {
            DatePickerSheetz(
                selectedDate: $endDate,
                minimumDate: Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? Date(),
                title: "Date de fin",
                onSave: {
                    showEndDatePicker = false
                }
            )
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blueH))
                .scaleEffect(1.5)
            
            Text("Traitement en cours...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Title Card
    private var titleCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blueH)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            VStack(spacing: 8) {
                Text("Sponsoriser un portefeuille")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Rectangle()
                    .fill(.white)
                    .frame(width: 80, height: 3)
            }
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - PIN Entry Card
    private var pinEntryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Entrer le code PIN")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.blueH)
            
            SecureField("****", text: $pin)
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
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Source Details Card
    private var sourceDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Source des Fonds")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.blueH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            HStack {
                Text("Numéro de Téléphone")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(userDataManager.getPhoneNumber())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            HStack {
                Text("Numéro de Portefeuille")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(userDataManager.getWalletNumber())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
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
            
            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    TextField("N° du destinataire", text: $recipientPhone)
                        .keyboardType(.numberPad)
                        .font(.system(size: 14, weight: .medium))
                        .padding(.leading, 12)
                        .onChange(of: recipientPhone) {
                            // Limit to 9 digits
                            if recipientPhone.count > 9 {
                                recipientPhone = String(recipientPhone.prefix(9))
                            }
                            
                            // Auto-verify when 9 digits are entered
                            if recipientPhone.count == 9 {
                                verifyRecipient()
                            } else if recipientPhone.count < 9 {
                                // Reset recipient info if digits are deleted
                                resetVerificationFields()
                            }
                        }
                    
                    if isVerifying {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blueH))
                            .scaleEffect(0.8)
                            .padding(.trailing, 12)
                    } else if isRecipientVerified && !recipientName.isEmpty && recipientPhone.count == 9 {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blueH)
                            .padding(.trailing, 12)
                    }
                }
                .frame(height: 48)
                .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                .cornerRadius(8)
                
                Button(action: { showContactPicker = true }) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(Color.blueH)
                        .cornerRadius(8)
                }
            }
            
            if isRecipientVerified && !recipientName.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "person.fill")
                        .foregroundColor(.blueH)
                        .font(.system(size: 14))
                    
                    Text(recipientName)
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
    
    // MARK: - Limits Card
    private var limitsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Limites")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.blueH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            HStack {
                FormattedTextField(placeholder: "Limite journalière", text: $dailyLimit)
                
                Rectangle()
                    .fill(Color.secondary)
                    .frame(width: 1)
                    .padding(.vertical, 8)
                
                Text("GNF")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
            }
            .background(Color(red: 0.96, green: 0.96, blue: 0.96))
            .cornerRadius(8)
            
            HStack {
                FormattedTextField(placeholder: "Limite mensuelle", text: $monthlyLimit)
                
                Rectangle()
                    .fill(Color.secondary)
                    .frame(width: 1)
                    .padding(.vertical, 8)
                
                Text("GNF")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
            }
            .background(Color(red: 0.96, green: 0.96, blue: 0.96))
            .cornerRadius(8)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Period Card
    private var periodCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Période")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.blueH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Date de début")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blueH)
                
                Button(action: {
                    showStartDatePicker = true
                }) {
                    HStack {
                        Text(formatDate(startDate))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "calendar")
                            .foregroundColor(.blueH)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 48)
                    .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                    .cornerRadius(8)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Date de fin")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blueH)
                
                Button(action: {
                    showEndDatePicker = true
                }) {
                    HStack {
                        Text(formatDate(endDate))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "calendar")
                            .foregroundColor(.blueH)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 48)
                    .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                    .cornerRadius(8)
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
        Button(action: {
            validateAndPrepare()
        }) {
            Text("Soumettre")
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
    
    // MARK: - Helper Methods
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }
    
    private func formatDateForAPI(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
    
    private func resetVerificationFields() {
        recipientName = ""
        sponsoredBankCode = ""
        isRecipientVerified = false
    }
    
    private func validateDateRange() {
        if endDate <= startDate {
            let newEndDate = Calendar.current.date(byAdding: .month, value: 3, to: startDate) ?? Date()
            endDate = newEndDate
            showError("Date ajustée", "La date de fin a été ajustée pour être postérieure à la date de début")
        }
    }
    
    // MARK: - Verify Recipient
    private func verifyRecipient() {
        guard recipientPhone.count == 9 else {
            return
        }
        
        isVerifying = true
        
        var request = RequestNameEnquiry()
        request.source = "P"
        request.phoneNumber = recipientPhone
        request.bank = "00100"
        request.pin = userDataManager.getPinForAPI()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyMMdd"
        let datePrefix = dateFormatter.string(from: Date())
        let randomDigits = String(format: "%06d", Int.random(in: 0...999999))
        request.requestId = datePrefix + randomDigits
        
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
                        self.showError("Erreur", apiError.message)
                    } else {
                        self.showError("Erreur", error.localizedDescription)
                    }
                    self.resetVerificationFields()
                }
            }
        }
    }
    
    private func handleVerificationSuccess(_ response: ResponseServiceJson) {
        if let result = response.result {
            let clientName = result["walletHolder"] as? String ?? ""
            let phoneConfirmed = result["phoneNumber"] as? String ?? ""
            
            if !recipientPhone.hasSuffix(phoneConfirmed.suffix(9)) && recipientPhone != phoneConfirmed {
                showError("Erreur", "Le numéro vérifié ne correspond pas au numéro saisi")
                resetVerificationFields()
                return
            }
            
            sponsoredBankCode = "00100"
            recipientName = clientName
            isRecipientVerified = true
        } else {
            showError("Erreur", "Information du destinataire non disponible")
            resetVerificationFields()
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
        
        showError("Erreur", errorMessage)
        resetVerificationFields()
    }
    
    // MARK: - Validate and Prepare
    private func validateAndPrepare() {
        guard validateInputs() else { return }
        
        showPinEntry = true
    }
    
    private func validateInputs() -> Bool {
        if recipientPhone.isEmpty {
            showError("Erreur", "Le numéro de téléphone est requis")
            return false
        }
        
        if !isRecipientVerified || recipientName.isEmpty {
            showError("Erreur", "Veuillez d'abord vérifier le destinataire")
            return false
        }
        
        if dailyLimit.isEmpty {
            showError("Erreur", "La limite journalière est requise")
            return false
        }
        
        if monthlyLimit.isEmpty {
            showError("Erreur", "La limite mensuelle est requise")
            return false
        }
        
        guard let daily = Double(dailyLimit.cleanCurrencyValue()),
              let monthly = Double(monthlyLimit.cleanCurrencyValue()) else {
            showError("Erreur", "Montants invalides")
            return false
        }
        
        if monthly < daily {
            showError("Erreur", "La limite mensuelle doit être supérieure ou égale à la limite journalière")
            return false
        }
        
        if showPinEntry && pin.isEmpty {
            showError("Erreur", "Veuillez entrer votre code PIN")
            return false
        }
        
        if showPinEntry {
            processSponsorWithPin()
            return false
        }
        
        return true
    }
    
    // MARK: - Process Sponsor
    private func processSponsorWithPin() {
        isLoading = true
        
        var request = SponsoredWalletDto()
        request.source = "P"
        request.phoneNumber = userDataManager.getPhoneNumber()
        request.walletNumber = userDataManager.getWalletNumber()
        request.bankCode = "00100"
        
        request.phoneNumberSponsored = recipientPhone
        request.walletNumberSponsored = ""
        request.bankCodeSponsored = sponsoredBankCode.isEmpty ? "00100" : sponsoredBankCode
        
        request.dailyLimit = dailyLimit.cleanCurrencyValue()
        request.monthlyLimit = monthlyLimit.cleanCurrencyValue()
        request.dateStart = formatDateForAPI(startDate) + " 00:00:00"
        request.dateEnd = formatDateForAPI(endDate) + " 23:59:59"
        
        request.pin = pin
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyMMdd"
        let datePrefix = dateFormatter.string(from: Date())
        let randomDigits = String(format: "%06d", Int.random(in: 0...999999))
        request.requestId = datePrefix + randomDigits
        
        let fullDateFormatter = DateFormatter()
        fullDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        request.requestDate = fullDateFormatter.string(from: Date())
        request.entityId = UserDataManager.shared.getUserCode()
        
        APIClient.shared.sponsorWallet(request: request) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.respCode == "000" {
                        self.showSuccessAndDismiss("Parrainage réussi")
                    } else {
                        self.showError("Erreur", response.message ?? "Échec du parrainage")
                    }
                case .failure(let error):
                    if let apiError = error as? APIError {
                        self.showError("Erreur", apiError.message)
                    } else {
                        self.showError("Erreur", error.localizedDescription)
                    }
                }
            }
        }
    }
    
    private func showError(_ title: String, _ message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
    
    private func showSuccess(_ message: String) {
        alertTitle = "Succès"
        alertMessage = message
        showAlert = true
    }
    
    private func showSuccessAndDismiss(_ message: String) {
        alertTitle = "Succès"
        alertMessage = message
        
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.dismiss()
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(alert, animated: true)
        }
    }
}

// MARK: - Date Picker Sheet
struct DatePickerSheetz: View {
    @Binding var selectedDate: Date
    let minimumDate: Date
    let title: String
    let onSave: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "",
                    selection: $selectedDate,
                    in: minimumDate...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()
                
                Spacer()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        onSave()
                    }
                }
            }
        }
    }
}
