//
//  BiometricSettingsView.swift
//  DiamaPay
//
//  Created by Bits on 2/10/2025.
//


import SwiftUI

struct BiometricSettingsView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @State private var biometricEnabled: Bool
    @State private var showPINPrompt = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isProcessing = false
    
    private let userDataManager = UserDataManager.shared
    
    init() {
        _biometricEnabled = State(initialValue: UserDataManager.shared.isBiometricEnabled())
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                DiamaPayHeader(title: "Biometric Settings", headerColor: Color(hex: "174EA6"))

                
                ScrollView {
                    VStack(spacing: 20) {
                        // Biometric Info Card
                        biometricInfoCard
                        
                        // Toggle Card
                        biometricToggleCard
                        
                        // Instructions Card
                        if biometricEnabled {
                            instructionsCard
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .padding()
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AppBottomBar(onSponsors: {}, onQR: {}, onLimits: {}, onSettings: {})
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showPINPrompt) {
            PINPromptView { pin in
                enableBiometric(with: pin)
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .overlay(
            Group {
                if isProcessing {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
        )
    }

    // MARK: - Biometric Info Card
    private var biometricInfoCard: some View {
        VStack(spacing: 16) {
            Image(systemName: BiometricHelper.getBiometricType().icon)
                .font(.system(size: 60))
                .foregroundColor(.blueH)
            
            Text(BiometricHelper.getBiometricType().displayName)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            Text(biometricStatusText)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Toggle Card
    private var biometricToggleCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Activer \(BiometricHelper.getBiometricTypeString())")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Connexion rapide et sécurisée")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $biometricEnabled)
                    .labelsHidden()
                    .onChange(of: biometricEnabled) {
                        handleToggleChange(biometricEnabled)
                    }
                    .disabled(!BiometricHelper.isBiometricAvailable() || isProcessing)
            }
            
            if !BiometricHelper.isBiometricAvailable() {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text(BiometricHelper.getBiometricStatus().message)
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                }
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Instructions Card
    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 20))
                
                Text("Comment ça marche")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                InstructionRow(
                    number: "1",
                    text: "À la prochaine connexion, vous verrez le bouton d'authentification biométrique"
                )
                
                InstructionRow(
                    number: "2",
                    text: "Appuyez sur le bouton et utilisez votre \(BiometricHelper.getBiometricTypeString())"
                )
                
                InstructionRow(
                    number: "3",
                    text: "Accédez instantanément à votre portefeuille"
                )
            }
            .padding(.top, 8)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Computed Properties
    private var biometricStatusText: String {
        if BiometricHelper.isBiometricAvailable() {
            return biometricEnabled ? 
                "La connexion biométrique est activée pour une connexion rapide et sécurisée" :
                "Activez la connexion biométrique pour une authentification plus rapide"
        } else {
            return BiometricHelper.getBiometricStatus().message
        }
    }
    
    // MARK: - Actions
    private func handleToggleChange(_ newValue: Bool) {
        if newValue {
            // Enabling - show PIN prompt
            showPINPrompt = true
        } else {
            // Disabling - just disable
            disableBiometric()
        }
    }
    
    private func enableBiometric(with pin: String) {
        isProcessing = true
        
        // Verify PIN is correct by attempting authentication
        BiometricHelper.authenticateWithCustomPrompt(
            reason: "Confirmer pour activer \(BiometricHelper.getBiometricTypeString())"
        ) { result in
            DispatchQueue.main.async {
                self.isProcessing = false
                
                switch result {
                case .success:
                    // Save PIN in Keychain
                    if self.userDataManager.saveBiometricCredentials(pin: pin) {
                        self.userDataManager.setUseBiometric(true)
                        self.alertTitle = "Succès"
                        self.alertMessage = "\(BiometricHelper.getBiometricTypeString()) activé avec succès"
                        self.showAlert = true
                        
                        //print("✅ Biometric login enabled successfully")
                    } else {
                        self.biometricEnabled = false
                        self.alertTitle = "Erreur"
                        self.alertMessage = "Impossible d'activer \(BiometricHelper.getBiometricTypeString())"
                        self.showAlert = true
                        
                        //print("❌ Failed to save biometric credentials")
                    }
                    
                case .failure(let error):
                    self.biometricEnabled = false
                    
                    // Don't show error for user cancellation
                    if case .userCancel = error {
                        return
                    }
                    
                    self.alertTitle = "Erreur"
                    self.alertMessage = error.localizedDescription
                    self.showAlert = true
                    
                    //print("❌ Biometric authentication failed: \(error)")
                }
            }
        }
    }
    
    private func disableBiometric() {
        userDataManager.setUseBiometric(false)
        
        alertTitle = "Désactivé"
        alertMessage = "\(BiometricHelper.getBiometricTypeString()) désactivé"
        showAlert = true
        
        //print("ℹ️ Biometric login disabled")
    }
}

// MARK: - Instruction Row
struct InstructionRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.blueH)
                .clipShape(Circle())
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct PINPromptView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var pin = ""
    @State private var showPassword = false
    @State private var isVerifying = false
    @State private var errorMessage = ""
    let onPINEntered: (String) -> Void
    
    private let userDataManager = UserDataManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 12) {
                    Image(systemName: BiometricHelper.getBiometricType().icon)
                        .font(.system(size: 60))
                        .foregroundColor(.blueH)
                    
                    Text("Activer \(BiometricHelper.getBiometricTypeString())")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Entrez votre PIN pour confirmer")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.blueH)
                            .frame(width: 20)
                        
                        if showPassword {
                            TextField("PIN", text: $pin)
                                .keyboardType(.numberPad)
                                .font(.system(size: 16, weight: .medium))
                        } else {
                            SecureField("PIN", text: $pin)
                                .keyboardType(.numberPad)
                                .font(.system(size: 16, weight: .medium))
                        }
                        
                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(errorMessage.isEmpty ? Color.gray.opacity(0.3) : Color.red, lineWidth: 1)
                    )
                    .onChange(of: pin) { newValue in
                        if newValue.count > 4 { pin = String(newValue.prefix(4)) }
                        errorMessage = ""
                    }
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                    
                    Button(action: verifyPin) {
                        if isVerifying {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Confirmer")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(pin.count == 4 ? Color.blueH : Color.gray)
                    .cornerRadius(8)
                    .disabled(pin.count != 4 || isVerifying)
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
            .background(Color.white)
            .navigationBarItems(
                leading: Button("Annuler") { presentationMode.wrappedValue.dismiss() }
                    .foregroundColor(.blueH)
            )
        }
    }
   
    private func verifyPin() {
        errorMessage = ""
        
        guard pin.count == 4 else {
            errorMessage = "Le PIN doit contenir exactement 4 chiffres"
            return
        }
        
        isVerifying = true
        
        PinVerificationService.verify(pin: pin) { verifiedPin in
            isVerifying = false
            onPINEntered(verifiedPin)
            presentationMode.wrappedValue.dismiss()
        } onFailure: { message in
            isVerifying = false
            errorMessage = message
            pin = ""
        }
    }
    
}

#Preview {
    BiometricSettingsView()
}
