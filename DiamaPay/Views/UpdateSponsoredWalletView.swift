//
//  UpdateSponsoredWalletView.swift
//  DiamaPay
//
//  Created by Bits on 30/9/2025.
//


//
//  UpdateSponsoredWalletView.swift
//  DiamaPay
//
//  Created by Assistant on 30/9/2025.
//

import SwiftUI

struct UpdateSponsoredWalletView: View {
    @Environment(\.presentationMode) var presentationMode
    let wallet: SponsoredWallet
    let onSuccess: () -> Void
    
    @State private var dailyLimit: String = ""
    @State private var monthlyLimit: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var pin: String = ""
    
    @State private var showStartDatePicker = false
    @State private var showEndDatePicker = false
    @State private var showConfirmation = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    private let userDataManager = UserDataManager.shared
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                DiamaPayHeader()

                if isLoading {
                    loadingView
                } else {
                    contentView
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadInitialData()
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) {
                if alertTitle == "Succès" {
                    onSuccess()
                }
            }
        } message: {
            Text(alertMessage)
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
        .overlay(confirmationOverlay)
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
    
    // MARK: - Content View
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Title Card
                titleCard
                
                // Beneficiary Info Card
                beneficiaryInfoCard
                
                // Limits Card
                limitsCard
                
                // Period Card
                periodCard
                
                // PIN Card
                pinCard
                
                // Update Button
                updateButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - Title Card
    private var titleCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blueH)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            VStack(spacing: 8) {
                Text("Mettre à jour les limites")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Rectangle()
                    .fill(.white)
                    .frame(width: 80, height: 3)
            }
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Beneficiary Info Card
    private var beneficiaryInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bénéficiaire: \(wallet.userNameSponsored)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.blueH)
            
            if !wallet.phoneNumberSponsored.isEmpty {
                Text(wallet.phoneNumberSponsored)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                    .foregroundColor(Color.greenH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            // Daily Limit - Use FormattedTextField
            HStack {
                FormattedTextField(
                    placeholder: "Limite journalière",
                    text: $dailyLimit,
                    maxLength: 15
                )
                
                Rectangle()
                    .fill(Color.secondary)
                    .frame(width: 1)
                    .padding(.vertical, 8)
                
                Text("GNF")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
            }
            .background(Color(red: 0.96, green: 0.96, blue: 0.96))
            .cornerRadius(8)
            
            // Monthly Limit - Use FormattedTextField
            HStack {
                FormattedTextField(
                    placeholder: "Limite mensuelle",
                    text: $monthlyLimit,
                    maxLength: 15
                )
                
                Rectangle()
                    .fill(Color.secondary)
                    .frame(width: 1)
                    .padding(.vertical, 8)
                
                Text("GNF")
                    .font(.system(size: 12, weight: .semibold))
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
                    .foregroundColor(Color.greenH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Date de début")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.blueH)
                
                Button(action: {
                    showStartDatePicker = true
                }) {
                    HStack {
                        Text(formatDate(startDate))
                            .font(.system(size: 12, weight: .medium))
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
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.blueH)
                
                Button(action: {
                    showEndDatePicker = true
                }) {
                    HStack {
                        Text(formatDate(endDate))
                            .font(.system(size: 12, weight: .medium))
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
    
    // MARK: - PIN Card
    private var pinCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Code PIN")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.blueH)
            
            SecureField("Entrer le code PIN", text: $pin)
                .keyboardType(.numberPad)
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
    
    // MARK: - Update Button
    private var updateButton: some View {
        Button(action: {
            validateAndShowConfirmation()
        }) {
            Text("Mettre à jour")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 150, height: 48)
                .background(Color.greenH)
                .cornerRadius(8)
        }
        .disabled(isLoading)
        .padding(.vertical, 16)
    }
    
    // MARK: - Confirmation Overlay
    private var confirmationOverlay: some View {
        Group {
            if showConfirmation {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Text("Confirmer la mise à jour")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirmer la mise à jour des limites pour \(wallet.userNameSponsored)?")
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                            
                            Divider()
                            
                            HStack {
                                Text("Limite journalière:")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(dailyLimit.formatAsCurrency()) GNF")
                                    .font(.system(size: 14, weight: .semibold))
                            }

                            HStack {
                                Text("Limite mensuelle:")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(monthlyLimit.formatAsCurrency()) GNF")  
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            
                            HStack {
                                Text("Période:")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(formatDate(startDate)) - \(formatDate(endDate))")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                showConfirmation = false
                            }) {
                                Text("Annuler")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color(UIColor.systemGray5))
                                    .cornerRadius(8)
                            }
                            
                            Button(action: {
                                showConfirmation = false
                                performUpdate()
                            }) {
                                Text("Mettre à jour")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.greenH)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(radius: 20)
                    .padding(.horizontal, 40)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func loadInitialData() {
        dailyLimit = wallet.dailyLimit
        monthlyLimit = wallet.monthlyLimit
        
        // Parse dates
        startDate = parseDate(wallet.startDate) ?? Date()
        endDate = parseDate(wallet.endDate) ?? Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    }
    
    private func parseDate(_ dateStr: String) -> Date? {
        let formats = ["yyyyMMddHHmm", "yyyy-MM-dd HH:mm:ss", "yyyyMMdd", "yyyy-MM-dd"]
        
        for format in formats {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            
            if let date = formatter.date(from: dateStr) {
                return date
            }
        }
        
        return nil
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }
    
    private func formatDateForAPI(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
    
    private func validateDateRange() {
        if endDate <= startDate {
            let newEndDate = Calendar.current.date(byAdding: .month, value: 3, to: startDate) ?? Date()
            endDate = newEndDate
            showError("Date ajustée", "La date de fin a été ajustée pour être postérieure à la date de début")
        }
    }
    
    private func validateAndShowConfirmation() {
        guard validateInputs() else { return }
        showConfirmation = true
    }
    
    private func validateInputs() -> Bool {
        if dailyLimit.isEmpty {
            showError("Erreur", "La limite journalière est requise")
            return false
        }
        
        if monthlyLimit.isEmpty {
            showError("Erreur", "La limite mensuelle est requise")
            return false
        }
        
        if pin.isEmpty {
            showError("Erreur", "Le code PIN est requis")
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
        
        if endDate <= startDate {
            showError("Erreur", "La date de fin doit être après la date de début")
            return false
        }
        
        return true
    }
    
    // MARK: - Perform Update
    private func performUpdate() {
        isLoading = true
        
        var request = SponsoredWalletDto()
        
        // User information
        let walletNumber = userDataManager.getWalletNumber()
        let phoneNumber = userDataManager.getPhoneNumber()
        let bankCode = userDataManager.getBankCode()
        
        // Set source
        if !walletNumber.isEmpty {
            request.source = "W"
            request.walletNumber = walletNumber
            request.phoneNumber = phoneNumber
        } else {
            request.source = "P"
            request.phoneNumber = phoneNumber
        }
        
        request.bankCode = bankCode
        request.walletNumberSponsored = wallet.walletNumberSponsored
        request.phoneNumberSponsored = wallet.phoneNumberSponsored
        request.bankCodeSponsored = wallet.bankCode.isEmpty ? bankCode : wallet.bankCode
        request.dailyLimit = dailyLimit.cleanCurrencyValue()
        request.monthlyLimit = monthlyLimit.cleanCurrencyValue()
        request.dateStart = formatDateForAPI(startDate)
        request.dateEnd = formatDateForAPI(endDate)
        request.pin = pin
        
        // Generate requestId
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyMMdd"
        let datePrefix = dateFormatter.string(from: Date())
        let randomDigits = String(format: "%06d", Int.random(in: 0...999999))
        request.requestId = datePrefix + randomDigits
        
        // Generate requestDate
        let fullDateFormatter = DateFormatter()
        fullDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        request.requestDate = fullDateFormatter.string(from: Date())
        request.entityId = UserDataManager.shared.getUserCode()
        
        APIClient.shared.updateSponsoredWallet(request: request) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.respCode == "000" {
                        self.showSuccess("Mise à jour réussie")
                    } else {
                        self.showError("Erreur", response.message ?? "Échec de la mise à jour")
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
}
