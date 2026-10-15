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
    @State private var alertTitle: String = "Erreur"
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
            Color.white
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
                        
                        Text("Traitement en cours...")
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
            AppBottomBar(onSponsors: {}, onQR: {}, onLimits: {}, onSettings: {})
        }
        .navigationBarHidden(true)
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) {
                if alertTitle == "Code PIN modifié" {
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
                Text("Changer votre PIN")
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
                Text("Informations du Portefeuille")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.blueH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            // Wallet Number
            HStack {
                Text("Portefeuille")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatWalletNumber(userDataManager.getWalletNumber()))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            // Balance
            HStack {
                Text("Solde")
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
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Current PIN Verification Card
    private var currentPinVerificationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Vérification du PIN actuel")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.blueH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            Text("Entrer le code PIN actuel")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.blueH)
            
            // PIN Input
            SecureField("****", text: $currentPin)
                .keyboardType(.numberPad)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                .cornerRadius(8)
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
                Text("Vérifier le PIN")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(isPinVerified ? Color.gray : Color.blueH)
                    .cornerRadius(8)
            }
            .disabled(isPinVerified || isLoading)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - New PIN Card
    private var newPinCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Nouveau PIN")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.blueH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            // New PIN
            Text("Entrer votre nouveau PIN")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.blueH)
            
            SecureField("****", text: $newPin)
                .keyboardType(.numberPad)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                .cornerRadius(8)
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
            Text("Confirmer votre nouveau PIN")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.blueH)
                .padding(.top, 8)
            
            SecureField("****", text: $confirmPin)
                .keyboardType(.numberPad)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                .cornerRadius(8)
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
                Text("Changer le PIN")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.blueH)
                    .cornerRadius(8)
            }
            .disabled(isLoading)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
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
                        Text("Confirmation de changement de PIN")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        // Message
                        Text("Confirmez-vous le changement de votre code PIN?\n\nCette action est irréversible et vous devrez utiliser le nouveau code PIN pour vos futures transactions.")
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
                                Text("Annuler")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.blueH)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(Color.blueH.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            
                            Button(action: {
                                showConfirmationDialog = false
                                changePin()
                            }) {
                                Text("Changer le PIN")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
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
            currentPinError = "Le code PIN est requis"
            showCurrentPinError = true
            return false
        }
        
        if pin.count < 4 {
            currentPinError = "Le code PIN doit contenir au moins 4 chiffres"
            showCurrentPinError = true
            return false
        }
        
        showCurrentPinError = false
        return true
    }
    
    private func validateNewPin() -> Bool {
        var isValid = true
        
        if newPin.isEmpty {
            newPinError = "Le code PIN est requis"
            showNewPinError = true
            isValid = false
        } else if newPin.count < 4 {
            newPinError = "Le code PIN doit contenir au moins 4 chiffres"
            showNewPinError = true
            isValid = false
        } else {
            showNewPinError = false
        }
        
        if confirmPin.isEmpty {
            confirmPinError = "La confirmation du code PIN est requise"
            showConfirmPinError = true
            isValid = false
        } else if newPin != confirmPin {
            confirmPinError = "Les codes PIN ne correspondent pas"
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
                        self.showErrorAlert(response.message ?? "Échec de la vérification. Code: \(response.respCode ?? "N/A")")
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
    
    private func handlePinVerificationSuccess() {
        currentVerifiedPin = currentPin
        withAnimation {
            isPinVerified = true
        }
        
        alertTitle = "Vérification réussie"
        alertMessage = "Votre code PIN actuel a été vérifié avec succès. Vous pouvez maintenant définir un nouveau code PIN."
        showAlert = true
    }
    
    private func showChangePinConfirmationDialog() {
        guard isPinVerified else {
            showErrorAlert("Veuillez d'abord vérifier votre code PIN actuel")
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
        
        // ❌ DO NOT SET source field - Android doesn't set it either
        // ❌ DO NOT SET phoneNumber - Android doesn't set it either
        // ❌ DO NOT SET entityId - Android doesn't set it either
        
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
                        self.showErrorAlert(response.message ?? "Transfert échoué: Erreur inconnue")
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
    private func handlePinChangeSuccess() {
        // Update PIN in UserDataManager
        userDataManager.savePinForAPI(newPin)
        
        // Clear fields
        clearAllFields()
        
        // Show success message
        alertTitle = "Code PIN modifié"
        alertMessage = "Votre code PIN a été modifié avec succès. Utilisez ce nouveau code PIN pour vos prochaines transactions."
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
        alertTitle = "Erreur"
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
