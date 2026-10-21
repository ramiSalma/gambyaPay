//
//  ChangePinView.swift
//  DiamaPay
//
//  Created by Bits on 1/10/2025.
//
//
//  ChangePinView.swift
//  DiamaPay
//
//  Created by Bits on [Date]
//

import SwiftUI

struct ChangePinView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - State Variables
    @State private var currentPin: String = ""
    @State private var newPin: String = ""
    @State private var confirmPin: String = ""
    
    @State private var isPinVerified: Bool = false
    @State private var currentVerifiedPin: String = ""
    
    @State private var isLoading: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = "Error"
    @State private var alertMessage: String = ""
    
    @State private var showCurrentPinError: Bool = false
    @State private var currentPinError: String = ""
    @State private var showNewPinError: Bool = false
    @State private var newPinError: String = ""
    @State private var showConfirmPinError: Bool = false
    @State private var confirmPinError: String = ""
    
    @State private var showConfirmationDialog: Bool = false
    @State private var showSuccessDialog: Bool = false
    
    private let userDataManager = UserDataManager.shared
    
    var body: some View {
        ZStack {
            Color(hex: "F5F8FD")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                DiamaPayHeader(title: "Change PIN", headerColor: Color(hex: "174EA6"))

                if isLoading {
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blueH))
                            .scaleEffect(1.5)
                        
                        Text("Processing...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Title Card
                            
                            // Wallet Info Card
                            walletInfoCard
                            
                            // Current PIN Verification Card
                            currentPinVerificationCard
                            
                            // New PIN Card (shown only after verification)
                            if isPinVerified {
                                newPinCard
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AppBottomBar(
                onSponsors: {}, onQR: {}, onLimits: {}, onSettings: {},
                selectedTab: "Settings",
                onHome: { presentationMode.wrappedValue.dismiss() }
            )
        }
        .navigationBarHidden(true)
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) {
                if alertTitle == "PIN changed" {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        } message: {
            Text(alertMessage)
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
                Text("Change your PIN")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Rectangle()
                    .fill(.white)
                    .frame(width: 80, height: 3)
            }
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Wallet Info Card
    private var walletInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Wallet information")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.blueH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            // Wallet Number
            HStack {
                Text("Wallet")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatWalletNumber(userDataManager.getWalletNumber()))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            // Balance
            HStack {
                Text("Balance")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(userDataManager.getFormattedBalance())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: "C8D9F0"), lineWidth: 1))
        .shadow(color: Color(hex: "174EA6").opacity(0.07), radius: 8, x: 0, y: 3)
    }
    
    // MARK: - Current PIN Verification Card
    private var currentPinVerificationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Verify current PIN")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.blueH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            Text("Enter your current PIN")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.blueH)
            
            // PIN Input
            SecureField("****", text: $currentPin)
                .keyboardType(.numberPad)
                .font(.system(size: 16, weight: .medium))
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(Color(hex: "F7FAFF"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "C8D9F0"), lineWidth: 1))
                .disabled(isPinVerified)
                .onChange(of: currentPin) {
                    if currentPin.count > 6 {
                        currentPin = String(currentPin.prefix(6))
                    }
                    if showCurrentPinError {
                        showCurrentPinError = false
                    }
                }
            
            if showCurrentPinError {
                Text(currentPinError)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
            
            // Verify Button
            Button(action: {
                verifyCurrentPin()
            }) {
                Text(isPinVerified ? "PIN verified" : "Verify PIN")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(isPinVerified ? Color(hex: "7D8A9B") : Color(hex: "174EA6"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isPinVerified || isLoading)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: "C8D9F0"), lineWidth: 1))
        .shadow(color: Color(hex: "174EA6").opacity(0.07), radius: 8, x: 0, y: 3)
    }
    
    // MARK: - New PIN Card
    private var newPinCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("New PIN")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.blueH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            // New PIN
            Text("Enter your new PIN")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.blueH)
            
            SecureField("****", text: $newPin)
                .keyboardType(.numberPad)
                .font(.system(size: 16, weight: .medium))
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(Color(hex: "F7FAFF"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "C8D9F0"), lineWidth: 1))
                .onChange(of: newPin) {
                    if newPin.count > 6 {
                        newPin = String(newPin.prefix(6))
                    }
                    if showNewPinError {
                        showNewPinError = false
                    }
                }
            
            if showNewPinError {
                Text(newPinError)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
            
            // Confirm PIN
            Text("Confirm your new PIN")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.blueH)
                .padding(.top, 8)
            
            SecureField("****", text: $confirmPin)
                .keyboardType(.numberPad)
                .font(.system(size: 16, weight: .medium))
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(Color(hex: "F7FAFF"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "C8D9F0"), lineWidth: 1))
                .onChange(of: confirmPin) {
                    if confirmPin.count > 6 {
                        confirmPin = String(confirmPin.prefix(6))
                    }
                    if showConfirmPinError {
                        showConfirmPinError = false
                    }
                }
            
            if showConfirmPinError {
                Text(confirmPinError)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
            
            // Change PIN Button
            Button(action: {
                showChangePinConfirmationDialog()
            }) {
                Text("Change PIN")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color(hex: "174EA6"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isLoading)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: "C8D9F0"), lineWidth: 1))
        .shadow(color: Color(hex: "174EA6").opacity(0.07), radius: 8, x: 0, y: 3)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    // MARK: - Confirmation Dialog Overlay
    private var confirmationDialogOverlay: some View {
        Group {
            if showConfirmationDialog {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showConfirmationDialog = false
                        }
                    
                    VStack(spacing: 20) {
                        // Title
                        Text("Confirm PIN change")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        // Message
                        Text("Are you sure you want to change your PIN?\n\nYou will need to use the new PIN for future transactions.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Divider()
                        
                        // Buttons
                        HStack(spacing: 12) {
                            Button(action: {
                                showConfirmationDialog = false
                            }) {
                                Text("Cancel")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.blueH)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(Color(hex: "EAF3FF"))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            
                            Button(action: {
                                showConfirmationDialog = false
                                changePin()
                            }) {
                                Text("Change PIN")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(Color(hex: "174EA6"))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(24)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "C8D9F0"), lineWidth: 1))
                    .shadow(radius: 20)
                    .padding(.horizontal, 32)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatWalletNumber(_ walletNumber: String) -> String {
        if walletNumber.isEmpty || walletNumber.count < 8 {
            return walletNumber
        }
        return "****" + walletNumber.suffix(4)
    }
    
    private func validateCurrentPin(_ pin: String) -> Bool {
        if pin.isEmpty {
            currentPinError = "PIN is required."
            showCurrentPinError = true
            return false
        }
        
        if pin.count < 4 {
            currentPinError = "PIN must contain at least 4 digits."
            showCurrentPinError = true
            return false
        }
        
        showCurrentPinError = false
        return true
    }
    
    private func validateNewPin() -> Bool {
        var isValid = true
        
        if newPin.isEmpty {
            newPinError = "PIN is required."
            showNewPinError = true
            isValid = false
        } else if newPin.count < 4 {
            newPinError = "PIN must contain at least 4 digits."
            showNewPinError = true
            isValid = false
        } else {
            showNewPinError = false
        }
        
        if confirmPin.isEmpty {
            confirmPinError = "Please confirm your new PIN."
            showConfirmPinError = true
            isValid = false
        } else if newPin != confirmPin {
            confirmPinError = "The PINs do not match."
            showConfirmPinError = true
            isValid = false
        } else {
            showConfirmPinError = false
        }
        
        return isValid
    }
    
    private func verifyCurrentPin() {
        guard validateCurrentPin(currentPin) else { return }
        
        isLoading = true
        
        // Create request
        var request = RequestCheckPin()
        request.pin = currentPin
        request.walletNumber = userDataManager.getWalletNumber()
        request.source = "W"
        request.entityId = UserDataManager.shared.getUserCode()
        
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
        
        APIClient.shared.checkPin(request: request) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.respCode == "000" {
                        self.handlePinVerificationSuccess()
                    } else {
                        self.showErrorAlert(response.message ?? "PIN verification failed. Code: \(response.respCode ?? "N/A")")
                    }
                case .failure(let error):
                    if let apiError = error as? APIError {
                        self.showErrorAlert("Error: \(apiError.message)")
                    } else {
                        self.showErrorAlert("Network error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func handlePinVerificationSuccess() {
        currentVerifiedPin = currentPin
        withAnimation {
            isPinVerified = true
        }
        
        alertTitle = "Verification successful"
        alertMessage = "Your current PIN has been verified. You can now set a new PIN."
        showAlert = true
    }
    
    private func showChangePinConfirmationDialog() {
        guard isPinVerified else {
            showErrorAlert("Verify your current PIN first.")
            return
        }
        
        guard validateNewPin() else {
            return
        }
        
        showConfirmationDialog = true
    }
    private func changePin() {
        isLoading = true
        
        // Create request - matching Android exactly
        var request = RequestChangePin()
        request.walletNumber = userDataManager.getWalletNumber()
        request.oldPinCode = currentVerifiedPin
        request.newPinCode = newPin
        request.confPinCode = confirmPin
        request.bank = "00100"
        
        request.phoneNumber = userDataManager.getPhoneNumber()
        request.source = request.walletNumber.isEmpty ? "P" : "W"
        request.entityId = userDataManager.getPhoneNumber()

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
        
        APIClient.shared.changePin(request: request) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.respCode == "000" {
                        self.handlePinChangeSuccess()
                    } else {
                        self.showErrorAlert(response.message ?? "Unable to change PIN. Please try again.")
                    }
                case .failure(let error):
                    if let apiError = error as? APIError {
                        self.showErrorAlert("Error: \(apiError.message)")
                    } else {
                        self.showErrorAlert("Network error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    private func handlePinChangeSuccess() {
        // Update PIN in UserDataManager
        userDataManager.savePinForAPI(newPin)
        
        // Clear fields
        clearAllFields()
        
        // Show success message
        alertTitle = "PIN changed"
        alertMessage = "Your PIN was changed successfully. Use your new PIN for future transactions."
        showAlert = true
    }
    
    private func clearAllFields() {
        currentPin = ""
        newPin = ""
        confirmPin = ""
        currentVerifiedPin = ""
        isPinVerified = false
    }
    
    private func showErrorAlert(_ message: String) {
        alertTitle = "Error"
        alertMessage = message
        showAlert = true
    }
}

// MARK: - Preview
struct ChangePinView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChangePinView()
        }
    }
}
