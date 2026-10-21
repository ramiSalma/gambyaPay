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
                            
                            // Recipient Details Card
                            recipientDetailsCard
                            
                            // Limits Card
                            limitsCard
                            
                            // Period Card
                            periodCard
                            
                            // Submit Button
                            submitButton
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 16)
                        .padding(.bottom, 30)
                    }
                }
            }
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
                title: "Start Date",
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
                title: "End Date",
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
            
            Text("Processing…")
                .font(.system(size: 14, weight: .medium))
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
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Authentication")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.blueH)

                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 96, height: 3)
            }
            
            SecureField("****", text: $pin)
                .keyboardType(.numberPad)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "4B5563"), lineWidth: 1.5))
                .cornerRadius(12)
                .onChange(of: pin) {
                    if pin.count > 4 {
                        pin = String(pin.prefix(4))
                    }
                }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
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
                Text("Wallet number")
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
                Text("Recipient Details")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.blueH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 96, height: 3)
            }
            
            HStack(alignment: .top, spacing: 10) {
                HStack(spacing: 8) {
                    TextField("Recipient Number", text: $recipientPhone)
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
                .frame(height: 54)
                .background(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "4B5563"), lineWidth: 1.5))
                .cornerRadius(12)
                
                Button(action: { showContactPicker = true }) {
                    VStack(spacing: 4) {
                        Image(systemName: "person.text.rectangle")
                            .font(.system(size: 25, weight: .medium))
                            .frame(width: 46, height: 44)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blueH, lineWidth: 1.5))
                        Text("Contacts")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.blueH)
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
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Limits Card
    private var limitsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Limits")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.blueH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 96, height: 3)
            }
            
            limitField(placeholder: "Daily Limit", text: $dailyLimit)
            
            limitField(placeholder: "Monthly Limit", text: $monthlyLimit)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Period Card
    private var periodCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Period")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.blueH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 96, height: 3)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Start date")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blueH)
                
                Button(action: {
                    showStartDatePicker = true
                }) {
                    HStack {
                        Text(formatDate(startDate))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Image(systemName: "calendar")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.blueH)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 44)
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "4B5563"), lineWidth: 1.5))
                    .cornerRadius(12)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("End date")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blueH)
                
                Button(action: {
                    showEndDatePicker = true
                }) {
                    HStack {
                        Text(formatDate(endDate))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Image(systemName: "calendar")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.blueH)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 44)
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "4B5563"), lineWidth: 1.5))
                    .cornerRadius(12)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Submit Button
    private var submitButton: some View {
        Button(action: {
            validateAndPrepare()
        }) {
            Text("Send")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 150)
                .frame(height: 52)
                .background(Color(hex: "174EA6"))
                .cornerRadius(8)
        }
        .disabled(isLoading)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    private func limitField(placeholder: String, text: Binding<String>) -> some View {
        FormattedTextField(placeholder: placeholder, text: text, sponsorFormStyle: true)
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
            showError("Date adjusted", "The end date was moved after the start date.")
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
                        self.showError("Error", apiError.message)
                    } else {
                        self.showError("Error", error.localizedDescription)
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
                showError("Error", "The verified number does not match the number entered.")
                resetVerificationFields()
                return
            }
            
            sponsoredBankCode = "00100"
            recipientName = clientName
            isRecipientVerified = true
        } else {
            showError("Error", "Recipient information is unavailable.")
            resetVerificationFields()
        }
    }
    
    private func handleVerificationError(_ response: ResponseServiceJson) {
        let errorMessage = response.message ?? {
            switch response.respCode {
            case "001": return "Wallet not found."
            case "003": return "Required request details are missing."
            case "005": return "Incorrect PIN."
            case "006": return "PIN is blocked."
            case "021": return "User is not authorized."
            default: return "Verification failed. Code: \(response.respCode ?? "N/A")"
            }
        }()
        
        showError("Error", errorMessage)
        resetVerificationFields()
    }
    
    // MARK: - Validate and Prepare
    private func validateAndPrepare() {
        guard validateInputs() else { return }
        
        showPinEntry = true
    }
    
    private func validateInputs() -> Bool {
        if recipientPhone.isEmpty {
            showError("Error", "Recipient phone number is required.")
            return false
        }
        
        if !isRecipientVerified || recipientName.isEmpty {
            showError("Error", "Please verify the recipient first.")
            return false
        }
        
        if dailyLimit.isEmpty {
            showError("Error", "Daily limit is required.")
            return false
        }
        
        if monthlyLimit.isEmpty {
            showError("Error", "Monthly limit is required.")
            return false
        }
        
        guard let daily = Double(dailyLimit.cleanCurrencyValue()),
              let monthly = Double(monthlyLimit.cleanCurrencyValue()) else {
            showError("Error", "Enter valid limit amounts.")
            return false
        }
        
        if monthly < daily {
            showError("Error", "Monthly limit must be at least the daily limit.")
            return false
        }
        
        if showPinEntry && pin.isEmpty {
            showError("Error", "Enter your PIN to continue.")
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
                        self.showSuccessAndDismiss("Wallet sponsored successfully.")
                    } else {
                        self.showError("Error", response.message ?? "Could not sponsor this wallet.")
                    }
                case .failure(let error):
                    if let apiError = error as? APIError {
                        self.showError("Error", apiError.message)
                    } else {
                        self.showError("Error", error.localizedDescription)
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
        alertTitle = "Success"
        alertMessage = message
        showAlert = true
    }
    
    private func showSuccessAndDismiss(_ message: String) {
        alertTitle = "Success"
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
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                    }
                }
            }
        }
    }
}
