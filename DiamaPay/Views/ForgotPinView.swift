//
//  ForgotPinView.swift
//  DiamaPay
//
//  Created by Bits on 2/10/2025.
//

import SwiftUI

struct ForgotPinView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - State Variables
    @State private var currentStep = 1
    @State private var phoneNumber = ""
    @State private var answer = ""
    @State private var newPin = ""
    @State private var confirmPin = ""
    @State private var finalOtp = ""
    
    // Flow control
    @State private var useFullFlow = true  // true = 4 steps, false = 3 steps
    
    // Tokens
    @State private var sessionToken = ""
    @State private var verificationToken = ""
    @State private var resetToken = ""
    @State private var securityQuestion: SecurityQuestion?
    
    // Security questions list
    @State private var securityQuestionsList: [SecurityQuestionItem] = []
    
    // UI State
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertTitle = "Erreur"
    @State private var alertMessage = ""
    
    var prefilledPhone: String?
    
    var body: some View {
        ZStack {
            Color(hex: "F3F6FA")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    Image("img")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .padding(.top, 10)
                        .padding(.bottom, 40)
                    
                    DiamaPayHeader(title: "Forgot PIN", headerColor: Color(hex: "174EA6"))
                        .padding(.bottom, 32)
                    
                    mainCard
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    
                    actionButtons
                        .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if let prefilled = prefilledPhone {
                phoneNumber = prefilled
            }
            loadSecurityQuestions()
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
   
    
    // MARK: - Main Card
    private var mainCard: some View {
        VStack(spacing: 0) {
            VStack(spacing: 24) {
                Text(stepTitle)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 0.18, green: 0.30, blue: 0.20))
                    .multilineTextAlignment(.center)
                    .padding(.top, 24)
                
                Text(stepDescription)
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                
                stepContent
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blueH))
                        .scaleEffect(1.2)
                        .padding(.bottom, 16)
                }
            }
        }
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Step Content
    @ViewBuilder
    private var stepContent: some View {
        if useFullFlow {
            // Full 4-step flow: Phone -> Question -> Reset -> OTP
            switch currentStep {
            case 1: phoneNumberStep
            case 2: questionStep
            case 3: resetPinStep
            case 4: finalOtpStep
            default: EmptyView()
            }
        } else {
            // Shortened 3-step flow: Phone -> Reset -> OTP
            switch currentStep {
            case 1: phoneNumberStep
            case 2: resetPinStep
            case 3: finalOtpStep
            default: EmptyView()
            }
        }
    }
    
    // MARK: - Individual Steps
    private var phoneNumberStep: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "phone.fill")
                    .foregroundColor(.blueH)
                    .frame(width: 20)
                
                TextField("N° de téléphone", text: $phoneNumber)
                    .keyboardType(.phonePad)
                    .font(.system(size: 16))
            }
            .padding()
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.blueH, lineWidth: 1))
        }
    }
    
    private var questionStep: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundColor(.blueH)
                
                Text(displayedQuestionText)
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0.18, green: 0.30, blue: 0.20))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.96, green: 0.96, blue: 0.96))
            .cornerRadius(4)
            
            HStack {
                Image(systemName: "pencil")
                    .foregroundColor(.blueH)
                    .frame(width: 20)
                
                TextField("Votre réponse", text: $answer)
                    .font(.system(size: 16))
                    .textInputAutocapitalization(.words)
            }
            .padding()
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.blueH, lineWidth: 1))
        }
    }
    
    private var resetPinStep: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "lock")
                    .foregroundColor(.blueH)
                    .frame(width: 20)
                
                SecureField("Nouveau PIN", text: $newPin)
                    .keyboardType(.numberPad)
                    .font(.system(size: 16))
            }
            .padding()
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.blueH, lineWidth: 1))
            
            HStack {
                Image(systemName: "lock")
                    .foregroundColor(.blueH)
                    .frame(width: 20)
                
                SecureField("Confirmer PIN", text: $confirmPin)
                    .keyboardType(.numberPad)
                    .font(.system(size: 16))
            }
            .padding()
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.blueH, lineWidth: 1))
        }
    }
    
    private var finalOtpStep: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "envelope.fill")
                    .foregroundColor(.blueH)
                    .frame(width: 20)
                
                TextField("Entrer OTP", text: $finalOtp)
                    .keyboardType(.numberPad)
                    .font(.system(size: 16))
            }
            .padding()
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.blueH, lineWidth: 1))
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button(action: handleBackButton) {
                Text(currentStep == 1 ? "Retour à la connexion" : "Retour")
                    .font(.system(size: 16))
                    .foregroundColor(.blueH)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            
            Button(action: handleActionButton) {
                Text(actionButtonText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.blueH)
                    .cornerRadius(4)
            }
            .disabled(isLoading)
            .opacity(isLoading ? 0.6 : 1.0)
        }
    }
    
    // MARK: - Computed Properties
    private var stepTitle: String {
        if useFullFlow {
            switch currentStep {
            case 1: return "Entrer votre numéro de téléphone"
            case 2: return "Question secrète"
            case 3: return "Réinitialiser PIN"
            case 4: return "Vérifier OTP"
            default: return ""
            }
        } else {
            switch currentStep {
            case 1: return "Entrer votre numéro de téléphone"
            case 2: return "Réinitialiser PIN"
            case 3: return "Vérifier OTP"
            default: return ""
            }
        }
    }
    
    private var stepDescription: String {
        if useFullFlow {
            switch currentStep {
            case 1: return "Saisissez votre numéro de téléphone enregistré"
            case 2: return "Répondez à votre question de sécurité pour vérifier votre identité"
            case 3: return "Saisissez votre nouveau code PIN à 4 chiffres"
            case 4: return "Entrez le code à 6 chiffres envoyé à \(maskPhoneNumber(phoneNumber))"
            default: return ""
            }
        } else {
            switch currentStep {
            case 1: return "Saisissez votre numéro de téléphone enregistré"
            case 2: return "Saisissez votre nouveau code PIN à 4 chiffres"
            case 3: return "Entrez le code à 6 chiffres envoyé à \(maskPhoneNumber(phoneNumber))"
            default: return ""
            }
        }
    }
    
    private var actionButtonText: String {
        if useFullFlow {
            switch currentStep {
            case 1: return "Suivant"
            case 2: return "Vérifier"
            case 3: return "Réinitialiser"
            case 4: return "Vérifier"
            default: return "Suivant"
            }
        } else {
            switch currentStep {
            case 1: return "Suivant"
            case 2: return "Réinitialiser"
            case 3: return "Vérifier"
            default: return "Suivant"
            }
        }
    }
    
    private var displayedQuestionText: String {
        guard let question = securityQuestion else {
            return "Chargement de la question..."
        }
        
        if let questionText = question.question, !questionText.isEmpty {
            return questionText
        }
        
        guard let questionId = question.actualId else {
            return "Question non disponible"
        }
        
        let matchedQuestion = securityQuestionsList.first { $0.id == questionId }
        return matchedQuestion?.question ?? "Question ID: \(questionId)"
    }
    
    // MARK: - Action Handlers
    private func handleActionButton() {
        if useFullFlow {
            switch currentStep {
            case 1: initiateForgotPin()
            case 2: verifySecurityQuestion()
            case 3: resetPin()
            case 4: verifyFinalOtp()
            default: break
            }
        } else {
            switch currentStep {
            case 1: initiateForgotPin()
            case 2: resetPin()
            case 3: verifyFinalOtp()
            default: break
            }
        }
    }
    
    private func handleBackButton() {
        if currentStep > 1 {
            currentStep -= 1
        } else {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    // MARK: - API Calls
    private func loadSecurityQuestions() {
        APIClient.shared.listSecurityQuestions { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.respCode == "000", let resultList = response.result {
                        self.parseSecurityQuestions(resultList)
                    }
                case .failure(let error):
                    print("Failed to load security questions: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func parseSecurityQuestions(_ resultList: [Any]) {
        securityQuestionsList = []
        
        for item in resultList {
            guard let dict = item as? [String: Any] else { continue }
            
            // Backend uses "questionId", not "id"
            let questionId = dict["questionId"] as? String ?? ""
            let question = dict["question"] as? String ?? ""
            let questionCode = dict["questionCode"] as? String
            
            if !questionId.isEmpty && !question.isEmpty {
                let questionItem = SecurityQuestionItem(
                    id: questionId,
                    question: question,
                    questionCode: questionCode
                )
                securityQuestionsList.append(questionItem)
            }
        }
        
        //print("Loaded \(securityQuestionsList.count) security questions")
    }
    
    // Step 1: Initiate - gets sessionToken and maybe question
    private func initiateForgotPin() {
        guard !phoneNumber.isEmpty else {
            showErrorAlert("Veuillez entrer votre numéro de téléphone")
            return
        }
        
        isLoading = true
        
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let request = ForgotPinInitiateRequest(phoneNumber: phoneNumber, deviceId: deviceId)
        
        APIClient.shared.initiateForgotPin(request: request) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.isSuccessful {
                        self.sessionToken = response.sessionToken ?? ""
                        
                        // ALWAYS use full flow (4 steps)
                        self.useFullFlow = true
                        self.securityQuestion = response.question
                        self.sessionToken = self.sessionToken
                        
                        // If backend says skip question, set a flag but still show the step
                        if response.respCode == "PROCEED_TO_BACKEND_OTP" {
                            // Backend will skip validation, but we still show the question step in UI
                            self.resetToken = self.sessionToken
                        }
                        
                        self.showSuccessAlert(response.message ?? "Veuillez répondre à votre question")
                        self.currentStep = 2  // Always go to question step
                    } else {
                        self.handleErrorResponse(response)
                    }
                case .failure(let error):
                    self.handleNetworkError(error)
                }
            }
        }
    }
    // Step 2 (full flow): Verify Security Question
    private func verifySecurityQuestion() {
        guard !answer.isEmpty else {
            showErrorAlert("Veuillez entrer votre réponse")
            return
        }
        
        isLoading = true
        
        let request = SecurityQuestionRequest(
            phoneNumber: phoneNumber,
            sessionToken: sessionToken,
            answer: answer        )
        
        APIClient.shared.verifySecurityQuestion(request: request) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.isSuccessful {
                        self.resetToken = response.resetToken ?? ""
                        self.showSuccessAlert(response.message ?? "Vérification réussie")
                        self.currentStep = 3
                    } else {
                        self.handleErrorResponse(response)
                    }
                case .failure(let error):
                    self.handleNetworkError(error)
                }
            }
        }
    }
    
    // Step 3 (full) or 2 (short): Reset PIN
    private func resetPin() {
        guard !newPin.isEmpty, !confirmPin.isEmpty else {
            showErrorAlert("Veuillez remplir tous les champs PIN")
            return
        }
        
        guard newPin.count == 4 else {
            showErrorAlert("Le PIN doit contenir 4 chiffres")
            return
        }
        
        guard newPin == confirmPin else {
            showErrorAlert("Les PINs ne correspondent pas")
            return
        }
        
        isLoading = true
        
        let request = PinResetRequest(
            phoneNumber: phoneNumber,
            newPin: newPin,
            confirmPin: confirmPin,
            resetToken: resetToken
        )
        
        APIClient.shared.resetPin(request: request) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.respCode == "OTP_SENT_BY_BACKEND" {
                        self.resetToken = response.authCode ?? ""
                        self.showSuccessAlert(response.message ?? "OTP envoyé")
                        self.currentStep += 1
                    } else if response.isSuccessful {
                        self.showSuccessAlert("PIN réinitialisé avec succès!")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    } else {
                        self.handleErrorResponse(response)
                    }
                case .failure(let error):
                    self.handleNetworkError(error)
                }
            }
        }
    }
    
    // Step 4 (full) or 3 (short): Verify Final OTP
    private func verifyFinalOtp() {
        guard !finalOtp.isEmpty, finalOtp.count == 6 else {
            showErrorAlert("Veuillez entrer un OTP à 6 chiffres valide")
            return
        }
        
        guard !resetToken.isEmpty else {
            showErrorAlert("Token non trouvé. Veuillez recommencer")
            return
        }
        
        isLoading = true
        
        let request = OtpResetVerificationRequest(
            phoneNumber: phoneNumber,
            otp: finalOtp,
            authCode: resetToken
        )
        
        APIClient.shared.verifyOtpReset(request: request) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.isSuccessful {
                        self.showSuccessAlert("PIN réinitialisé avec succès!")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    } else {
                        self.handleErrorResponse(response)
                    }
                case .failure(let error):
                    self.handleNetworkError(error)
                }
            }
        }
    }
    
    // MARK: - Error Handling
    private func handleErrorResponse(_ response: ForgotPinResponse) {
        var message = response.message ?? "Une erreur s'est produite"
        
        if let respCode = response.respCode {
            switch respCode {
            case "RATE_LIMIT_EXCEEDED":
                message = "Trop de tentatives. Veuillez réessayer plus tard"
            case "ACCOUNT_BLOCKED":
                message = "Votre compte est bloqué. Veuillez contacter le support client"
            case "INVALID_OTP":
                message = "OTP invalide. Veuillez vérifier et réessayer"
            case "INVALID_ANSWER":
                message = "Réponse incorrecte. Veuillez réessayer"
            default:
                break
            }
        }
        
        showErrorAlert(message)
    }
    
    private func handleNetworkError(_ error: Error) {
        if let apiError = error as? APIError {
            showErrorAlert(apiError.message)
        } else {
            showErrorAlert("Erreur réseau: \(error.localizedDescription)")
        }
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
    
    private func maskPhoneNumber(_ phoneNumber: String) -> String {
        guard phoneNumber.count >= 4 else { return "****" }
        
        let start = String(phoneNumber.prefix(2))
        let end = String(phoneNumber.suffix(2))
        let middle = String(repeating: "*", count: phoneNumber.count - 4)
        
        return start + middle + end
    }
}

struct ForgotPinView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ForgotPinView()
        }
    }
}
