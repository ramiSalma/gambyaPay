//
//  BiometricSettingsView.swift
//  DiamaPay
//
//  Created by Bits on 2/10/2025.
//


import SwiftUI

struct BiometricSettingsView: View {
    @ObservedObject private var localization = AppLanguageStore.shared
    
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
                DiamaPayHeader(title: AppStrings.biometricSettings, headerColor: Color(hex: "174EA6"))

                
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
            Button(AppStrings.ok, role: .cancel) { }
        } message: {
            Text(AppStrings.option(alertMessage))
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
                    Text(AppStrings.activerValue(String(describing: BiometricHelper.getBiometricTypeString())))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(AppStrings.connexionRapideEtSecurisee)
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
                
                Text(AppStrings.commentCaMarche)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                InstructionRow(
                    number: "1",
                    text: AppStrings.aLaProchaineConnexionVousVerrezLeBoutonDAuthentification
                )
                
                InstructionRow(
                    number: "2",
                    text: AppStrings.appuyezSurLeBoutonEtUtilisezVotreValue(String(describing: BiometricHelper.getBiometricTypeString()))
                )
                
                InstructionRow(
                    number: "3",
                    text: AppStrings.accedezInstantanementAVotrePortefeuille
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
                AppStrings.laConnexionBiometriqueEstActiveePourUneConnexionRapideEt :
                AppStrings.activezLaConnexionBiometriquePourUneAuthentificationPlusRapide
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
            reason: AppStrings.confirmerPourActiverValue(String(describing: BiometricHelper.getBiometricTypeString()))
        ) { result in
            DispatchQueue.main.async {
                self.isProcessing = false
                
                switch result {
                case .success:
                    // Save PIN in Keychain
                    if self.userDataManager.saveBiometricCredentials(pin: pin) {
                        self.userDataManager.setUseBiometric(true)
                        self.alertTitle = AppStrings.succes
                        self.alertMessage = AppStrings.valueActiveAvecSucces(String(describing: BiometricHelper.getBiometricTypeString()))
                        self.showAlert = true
                        
                        //print("✅ Biometric login enabled successfully")
                    } else {
                        self.biometricEnabled = false
                        self.alertTitle = AppStrings.error
                        self.alertMessage = AppStrings.impossibleDActiverValue(String(describing: BiometricHelper.getBiometricTypeString()))
                        self.showAlert = true
                        
                        //print("❌ Failed to save biometric credentials")
                    }
                    
                case .failure(let error):
                    self.biometricEnabled = false
                    
                    // Don't show error for user cancellation
                    if case .userCancel = error {
                        return
                    }
                    
                    self.alertTitle = AppStrings.error
                    self.alertMessage = error.localizedDescription
                    self.showAlert = true
                    
                    //print("❌ Biometric authentication failed: \(error)")
                }
            }
        }
    }
    
    private func disableBiometric() {
        userDataManager.setUseBiometric(false)
        
        alertTitle = AppStrings.desactive
        alertMessage = AppStrings.valueDesactive(String(describing: BiometricHelper.getBiometricTypeString()))
        showAlert = true
        
        //print("ℹ️ Biometric login disabled")
    }
}

// MARK: - Instruction Row
struct InstructionRow: View {
    @ObservedObject private var localization = AppLanguageStore.shared
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
    @ObservedObject private var localization = AppLanguageStore.shared
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
                    
                    Text(AppStrings.activerValue(String(describing: BiometricHelper.getBiometricTypeString())))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(AppStrings.entrezVotrePinPourConfirmer)
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
                            TextField(AppStrings.pin, text: $pin)
                                .keyboardType(.numberPad)
                                .font(.system(size: 16, weight: .medium))
                        } else {
                            SecureField(AppStrings.pin, text: $pin)
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
                        Text(AppStrings.option(errorMessage))
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                    
                    Button(action: verifyPin) {
                        if isVerifying {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(AppStrings.confirmer)
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
                leading: Button(AppStrings.annuler) { presentationMode.wrappedValue.dismiss() }
                    .foregroundColor(.blueH)
            )
        }
    }
   
    private func verifyPin() {
        errorMessage = ""
        
        guard pin.count == 4 else {
            errorMessage = AppStrings.lePinDoitContenirExactement4Chiffres
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
