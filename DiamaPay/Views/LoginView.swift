import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var otpPhoneNumber = ""
    @State private var otpDeviceId = ""
    @StateObject private var otpDataObject = OtpData()
    @State private var phoneNumber = ""
    @State private var pin = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Error"
    @State private var navigateToOtp = false
    @State private var navigateToSignUp = false
    @State private var showBiometricButton = false
    @State private var otpData: (phoneNumber: String, deviceId: String) = ("", "")
    @State private var showVersionUpdateAlert = false
    @State private var versionUpdateMessage = ""
//    @State private var navigateToForcePinChange = false
//    @State private var phoneNumberForPinChange = ""
//    @State private var pinChangeReason = ""
    struct ForcePinChangeData: Identifiable {
        let id = UUID()
        let phoneNumber: String
        let reason: String
    }
    @State private var forcePinChangeData: ForcePinChangeData?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    private let apiClient = APIClient.shared
    
    // Responsive sizing
    private var isCompact: Bool {
        horizontalSizeClass == .compact || verticalSizeClass == .compact
    }
    
    private var logoSize: CGFloat {
        isCompact ? 170 : 190
    }
    
    private var titleFontSize: CGFloat {
        isCompact ? 22 : 28
    }
    
    private var maxFormWidth: CGFloat {
        horizontalSizeClass == .regular ? 500 : .infinity
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Header section with logo
                    headerSection
                        .frame(height: geometry.size.height * 0.35)
                    
                    // Form section
                    formSection
                        .frame(maxWidth: maxFormWidth)
                        .padding(.horizontal, horizontalPadding)
                    
                    Spacer(minLength: 34)
                    
                    // Footer section
                    footerSection
                        .padding(.bottom, 36)
                }
                .frame(minHeight: geometry.size.height)
            }
        }
        .background(Color.white)
        .ignoresSafeArea(edges: .top)
        .onAppear(perform: setupView)
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .alert("Mise à Jour Requise", isPresented: $showVersionUpdateAlert) {
            Button("Mettre à Jour") {
                openAppStore()
            }
            Button("Quitter", role: .destructive) {
                exit(0)
            }
        } message: {
            Text(versionUpdateMessage)
        }
        .sheet(isPresented: $navigateToOtp, onDismiss: {
            otpDataObject.clear()
        }) {
            OtpVerificationView(
                phoneNumber: otpDataObject.phoneNumber,
                deviceId: otpDataObject.deviceId
            )
            .environmentObject(authManager)
            .environmentObject(otpDataObject)  // ✅ Pass the object too
        }
        .sheet(isPresented: $navigateToSignUp) {
            RegistrationFlowView()
        }
//        .fullScreenCover(isPresented: $navigateToForcePinChange) {
//            ForcePinChangeView(
//                phoneNumber: phoneNumberForPinChange,
//                reason: pinChangeReason
//            )
//            .environmentObject(authManager)
//        }
        .fullScreenCover(item: $forcePinChangeData) { data in
            ForcePinChangeView(
                phoneNumber: data.phoneNumber,
                reason: data.reason
            )
            .environmentObject(authManager)
        }
    }
    
    // MARK: - View Components
    
    private var backgroundGradient: some View {
        Color.white
    }
    
    private var headerSection: some View {
        GeometryReader { proxy in
            ZStack {
                LoginHeaderShape().fill(Color(hex: "174EA6"))
                Image("logo_diama")
                    .resizable()
                    .scaledToFit()
                    .frame(width: logoSize, height: logoSize)
                    .position(x: proxy.size.width / 2, y: proxy.size.height * 0.51)
            }
        }
        .accessibilityElement(children: .combine)
    }
    
    private var formSection: some View {
        VStack(spacing: 18) {
            // Title section
            titleSection
            
            // Input fields
            inputFieldsSection
            
            // Action buttons
            actionButtonsSection
        }
        .padding(.top, 55)
        .padding(.bottom, 22)
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Welcome Back to")
                .foregroundColor(Color(hex: "174EA6"))
            Text("Your Secure Digital Wallet")
                .foregroundColor(Color(hex: "0788B9"))
        }
        .font(.system(size: titleFontSize + 3, weight: .bold))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var inputFieldsSection: some View {
        VStack(spacing: 20) {
            // Phone number field
            CustomTextField1(
                icon: "phone.fill",
                placeholder: "Phone Number",
                text: $phoneNumber,
                keyboardType: .phonePad,
                disabled: isLoading
            )
            .onChange(of: phoneNumber) {
                if phoneNumber.count > 9 {
                    phoneNumber = String(phoneNumber.prefix(9))
                }
            }
            
            // PIN field
            CustomSecureField(
                icon: "lock.fill",
                placeholder: "PIN",
                text: $pin,
                showPassword: $showPassword,
                disabled: isLoading
            )
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Login button
            PrimaryButton(
                title: isLoading ? "LOGGING IN..." : "Login",
                isLoading: isLoading,
                disabled: isLoading || phoneNumber.isEmpty || pin.isEmpty,
                action: performLogin
            )
            
            // Biometric button
            if showBiometricButton {
                BiometricButton(
                    disabled: isLoading,
                    action: performBiometricLogin
                )
                .transition(.scale.combined(with: .opacity))
            }
            
            // Forgot PIN button
            Button(action: showForgotPinAlert) {
                Text("Forgot PIN?")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(Color(hex: "0788B9"))
            }
            .disabled(isLoading)
            .padding(.top, 18)
        }
    }
    
    private var footerSection: some View {
        VStack(spacing: 42) {
            HStack(spacing: 8) {
                Text("No Account?")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(Color(hex: "222222"))
                
                Button(action: { navigateToSignUp = true }) {
                    Text("Sign Up")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(hex: "0788B9"))
                }
                .disabled(isLoading)
            }
            
            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "0788B9"))
        }
    }
    
    // MARK: - Computed Properties
    
    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 40 : 30
    }
    
    // MARK: - Setup Methods
    
    private func setupView() {
        apiClient.initialize(with: UserDataManager.shared)
        setupBiometricButton()
        
        NotificationCenter.default.addObserver(
            forName: .tokenExpired,
            object: nil,
            queue: .main
        ) { _ in
            handleTokenExpiration()
        }
    }
    
    private func setupBiometricButton() {
        let phoneNumber = UserDataManager.shared.getPhoneNumber()
        let biometricEnabled = UserDataManager.shared.isBiometricEnabled()
        let biometricAvailable = BiometricHelper.isBiometricAvailable()
        let hasCredentials = !phoneNumber.isEmpty &&
                            KeychainManager.shared.retrieve(for: "biometric_\(phoneNumber)") != nil
        
        let shouldShow = biometricEnabled && biometricAvailable && hasCredentials
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            self.showBiometricButton = shouldShow
            
            if !phoneNumber.isEmpty && self.phoneNumber.isEmpty {
                self.phoneNumber = phoneNumber
            }
        }
        
    }
    
    private func handleTokenExpiration() {
        showAlertMessage("Session expired. Please login again.", title: "Session Expired")
        setupBiometricButton()
    }
    
    private func performLogin() {
        guard !phoneNumber.isEmpty && !pin.isEmpty else {
            showAlertMessage("Veuillez remplir tous les champs")
            return
        }
        
        setLoading(true)
        
        let capturedPhoneNumber = self.phoneNumber
        let capturedPin = self.pin
        
        let request = AuthRequest(phoneNumber: capturedPhoneNumber, pin: capturedPin, deviceId: APIClient.getDeviceId())
        
        apiClient.login(request: request) { result in
            DispatchQueue.main.async {
                self.setLoading(false)
                
                self.handleLoginResponse(result, pin: capturedPin, phoneNumber: capturedPhoneNumber)
            }
        }
    }
    private func performBiometricLogin() {
 
        let phoneNumber = UserDataManager.shared.getPhoneNumber()
        guard !phoneNumber.isEmpty else {
            showAlertMessage("Session expired. Please login with your PIN.", title: "Session Expired")
            return
        }
        
        guard let savedPin = KeychainManager.shared.retrieve(for: "biometric_\(phoneNumber)") else {
            showAlertMessage("Biometric credentials not found. Please login with your PIN.", title: "Error")
            UserDataManager.shared.setUseBiometric(false)
            setupBiometricButton()
            return
        }
        
        guard BiometricHelper.isBiometricAvailable() else {
            let status = BiometricHelper.getBiometricStatus()
            showAlertMessage(status.message, title: "Biometric Unavailable")
            return
        }
        
        BiometricHelper.authenticateWithCustomPrompt { [self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                  
                    self.setLoading(true)
                
                    let capturedPhoneNumber = phoneNumber
                    
                    let request = AuthRequest(phoneNumber: capturedPhoneNumber, pin: savedPin, deviceId: APIClient.getDeviceId())
                    
                    self.apiClient.login(request: request) { loginResult in
                        DispatchQueue.main.async {
                            self.setLoading(false)
                            self.handleLoginResponse(loginResult, pin: savedPin, phoneNumber: capturedPhoneNumber)
                        }
                    }
                    
                case .failure(let error):
                    print("❌ Biometric authentication failed: \(error.localizedDescription)")
                    
                    if case .userCancel = error {
                        return
                    }
                    
                    self.showAlertMessage(error.localizedDescription, title: "Authentication Failed")
                }
            }
        }
    }
    
    private func handleLoginResponse(_ result: Result<AuthResponse, Error>, pin: String, phoneNumber: String) {
        print("""
        
        ==================== 🟣 AUTH RESPONSE OBJECT  before ====================
        \(result)
        ==================================================================
        
        """)
        switch result {
            
        case .success(let authResponse):
            // Success case - user logged in successfully
            print("✅ SUCCESS")
            print("🔵 respCode:", authResponse.respCode ?? "nil")

                print("🔵 success:", authResponse.success ?? false)
                print("🔵 message:", authResponse.message ?? "nil")
                print("🔵 requiresPinChange:", authResponse.requiresPinChange ?? false)

                print("➡️ Going to handleAuthResponse")
            
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

            if let jsonData = try? encoder.encode(authResponse),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                
                print("""
                
                ==================== 🟣 AUTH RESPONSE OBJECT ====================
                \(jsonString)
                ==================================================================
                
                """)
            }
            handleAuthResponse(authResponse, pin: pin)
            
        case .failure(let error):
            if let apiError = error as? APIError {
                let message = apiError.message ?? ""
                
                print("""
                
                ==================== 🟣 apiError  ====================
                \(apiError)
                ==================================================================
                
                """)
                // ============================================================
                // CHECK 1: Rate Limiting (HIGHEST PRIORITY)
                // ============================================================
                if message.contains("Too many") || message.contains("try again later") {
                    showAlertMessage("Trop de tentatives. Veuillez réessayer dans quelques minutes.", title: "Limite Atteinte")
                    return
                }
                
                // ============================================================
                // CHECK 2: OTP VERIFICATION REQUIRED (MOST COMMON)
                // ============================================================
//                if (apiError.respCode == "403" || apiError.respCode == "831") &&
                if (apiError.respCode == "831") &&
                   (message.contains("OTP") || message.contains("verification required")) {
                    
                    let deviceId = APIClient.getDeviceId()
                    
                    self.otpDataObject.set(phoneNumber: phoneNumber, deviceId: deviceId)
                    
                    self.navigateToOtp = true
                    return
                }
                // ============================================================
                // CHECK 3: Version Update Required
                // ============================================================
                if apiError.respCode == "403" &&
                   apiError.details == "VERSION_UPDATE_REQUIRED" &&
                   !message.contains("OTP") {
                    
                    let updateMessage = "Une nouvelle version de l'application est disponible. Veuillez mettre à jour pour continuer."
                    showVersionUpdateAlert(message: updateMessage)
                    return
                }
                
                // ============================================================
                // CHECK 6:ACCOUNT BLOKED
                // ============================================================
                if apiError.respCode == "805"
                   {
                    showAlertMessage("Votre compte est bloqué. Veuillez contacter le service client.",title: "Compte Bloqué")
                    return
                }
                

                // ============================================================
                // CHECK 4: PIN Change Required
                // ============================================================

                
//                    self.phoneNumberForPinChange = phoneNumber
//
//                    // Change title depending on the response code
//                    if apiError.respCode == "FIRST_CONNECTION" {
//                        self.alertTitle = "Premier accès"
//                    self.alertMessage = message
//                    self.showAlert = true
//
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//                        self.pinChangeReason = "FIRST_CONNECTION"
//                        self.navigateToForcePinChange = true
//                    }
//                        return
//                    }
                    
                if apiError.respCode == "FIRST_CONNECTION" {

                    print("🟢 FIRST_CONNECTION detected")
                    print("🟢 phoneNumber =", phoneNumber)
                    print("🟢 reason = FIRST_CONNECTION")

                    self.alertTitle = "Premier accès"
                    self.alertMessage = message
                    self.showAlert = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.forcePinChangeData = ForcePinChangeData(
                            phoneNumber: phoneNumber,
                            reason: "FIRST_CONNECTION"
                        )

                        print("🟢 Opening ForcePinChangeView")
                        print("🟢 reason sent = FIRST_CONNECTION")
                    }

                    return
                }
        // pin expired 
                
                if apiError.respCode == "PIN_EXPIRED" ||
                    apiError.respCode == "PIN_CHANGE_REQUIRED" {

                    print("🔵 PIN change required")
                    print("🔵 reason = PIN_EXPIRED")

                    alertTitle = "Code PIN Expiré"
                    alertMessage = apiError.message ??
                        "Votre code PIN a expiré. Vous devez le modifier pour continuer."

                    showAlert = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.forcePinChangeData = ForcePinChangeData(
                            phoneNumber: phoneNumber,
                            reason: "PIN_EXPIRED"
                        )
                    }

                    return
            }
                // ============================================================
                // CHECK 5: Account Locked
                // ============================================================
                if message.lowercased().contains("locked") ||
                   message.lowercased().contains("bloqué") {
                    showAlertMessage("Votre compte est bloqué. Veuillez contacter le service client.", title: "Compte Bloqué")
                    return
                }
                
                // ============================================================
                // CHECK 6: Invalid Credentials
                // ============================================================
                if message.contains("Invalid credentials") ||
                   message.contains("Incorrect") ||
                   message.contains("incorrect") {
                    showAlertMessage("Numéro de téléphone ou PIN incorrect.", title: "Erreur de Connexion")
                    return
                }
                
                // ============================================================
                // CHECK 7: Account Not Found
                // ============================================================
                if message.contains("not found") ||
                   message.contains("introuvable") {
                    showAlertMessage("Compte introuvable. Veuillez vérifier votre numéro de téléphone.", title: "Compte Introuvable")
                    return
                }
                
                // ============================================================
                // CHECK 8: Generic API Error (DEFAULT)
                // ============================================================
                showAlertMessage(apiError.message ?? "Une erreur est survenue", title: "Erreur")
                
            } else {
                // ============================================================
                // Network Error (not API error)
                // ============================================================
                let errorMessage = "Erreur de connexion: \(error.localizedDescription)"
                showAlertMessage(errorMessage, title: "Erreur Réseau")
            }
        }
    }
  
    private func handleAuthResponse(_ authResponse: AuthResponse, pin: String) {
        print("🔵 handleAuthResponse:", authResponse)

        
        if let requiresPinChange = authResponse.requiresPinChange, requiresPinChange {
            if authResponse.respCode == "PIN_EXPIRED" ||
               authResponse.respCode == "PIN_CHANGE_REQUIRED" {
                print("🔵2 respCode:", authResponse.respCode ?? "nil")
                if let requiresPinChange = authResponse.requiresPinChange, requiresPinChange {

                    if authResponse.respCode == "PIN_EXPIRED" ||
                       authResponse.respCode == "PIN_CHANGE_REQUIRED" {

                        print("🔵 PIN change required")
                        print("🔵 reason = PIN_EXPIRED")

                        alertTitle = "Code PIN Expiré"
                        alertMessage = authResponse.message ??
                            "Votre code PIN a expiré. Vous devez le modifier pour continuer."

                        showAlert = true

                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            self.forcePinChangeData = ForcePinChangeData(
                                phoneNumber: phoneNumber,
                                reason: "PIN_EXPIRED"
                            )
                        }

                        return
                    }
                }
//                phoneNumberForPinChange = phoneNumber
//                self.pinChangeReason = "PIN_EXPIRED"
//                alertTitle = "Code PIN Expiré"
//                alertMessage = authResponse.message ?? "Votre code PIN a expiré. Vous devez le modifier pour continuer."
//                showAlert = true
//                
//                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//                    navigateToForcePinChange = true
//                }
//                return
            }
        }
        
        guard let success = authResponse.success, success else {
            handleLoginFailure(authResponse)
            return
        }
        
        handleLoginSuccess(authResponse, pin: pin)
    }
    
    private func handleLoginFailure(_ authResponse: AuthResponse) {
        let respCode = authResponse.respCode
        let message = authResponse.message
        print("🔵1 respCode:", authResponse.respCode ?? "nil")

        if respCode == "OTP_REQUIRED" || message == "OTP verification required" {
            let deviceId = APIClient.getDeviceId()
            otpData = (phoneNumber: phoneNumber, deviceId: deviceId)
            navigateToOtp = true
            return
        }
        
        let errorMessage = message ?? "Login failed"
        showAlertMessage(errorMessage, title: "Login Failed")
    }
    
    private func handleLoginSuccess(_ authResponse: AuthResponse, pin: String) {
        
        guard let token = authResponse.token?.trimmingCharacters(in: .whitespacesAndNewlines),
              !token.isEmpty else {
        
            showAlertMessage("Login error: No authentication token received", title: "Login Error")
            return
        }
        
        UserDataManager.shared.savePinForAPI(pin)
        UserDataManager.shared.saveUserData(from: authResponse)
        
        let savedToken = UserDataManager.shared.getToken()
        
        if savedToken.isEmpty {
            showAlertMessage("Login error: Could not save authentication data", title: "Login Error")
            return
        }
        
        apiClient.updateToken(token)
        
        if BiometricHelper.isBiometricAvailable() {
            _ = UserDataManager.shared.saveBiometricCredentials(pin: pin)
        }
        
        DispatchQueue.main.async {
            authManager.login()
        }
        
        if BiometricHelper.shouldPromptForBiometricSetup() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                promptForBiometricSetup()
            }
        }
    }
    
    private func promptForBiometricSetup() {
        let biometricType = BiometricHelper.getBiometricTypeString()
        
        let alert = UIAlertController(
            title: "Activer \(biometricType)?",
            message: "Voulez-vous utiliser \(biometricType) pour un accès plus rapide et plus sécurisé à votre portefeuille?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Activer", style: .default) { _ in
            BiometricHelper.markBiometricSetupPrompted()
            UserDataManager.shared.setUseBiometric(true)
        })
        
        alert.addAction(UIAlertAction(title: "Pas maintenant", style: .cancel) { _ in
            BiometricHelper.markBiometricSetupPrompted()
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
    
    // MARK: - Helper Methods
    
    private func setLoading(_ loading: Bool) {
        withAnimation(.easeInOut(duration: 0.2)) {
            isLoading = loading
        }
    }
    
    private func showAlertMessage(_ message: String, title: String = "Error") {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
    
    private func showForgotPinAlert() {
        alertTitle = "Code PIN Oublié"
        alertMessage = "Merci de contacter le service client muni de votre pièce d'identité pour des questions de sécurité"
        showAlert = true
    }
    
    private func showVersionUpdateAlert(message: String) {
        versionUpdateMessage = message
        showVersionUpdateAlert = true
    }
    
    private func openAppStore() {
        if let url = URL(string: "https://apps.apple.com/us/app/diamacash/id6754772255") {
            UIApplication.shared.open(url)
        } else if let url = URL(string: "https://apps.apple.com/us/app/diamacash/id6754772255") {
            UIApplication.shared.open(url)
        }
    }
}

private struct LoginHeaderShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let edgeY = rect.height * 0.88
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: edgeY))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: edgeY),
            control: CGPoint(x: rect.midX, y: rect.height * 1.11)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Custom Components

struct CustomTextField1: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var disabled: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 21, weight: .medium))
                .foregroundColor(Color(hex: "174EA6"))
                .frame(width: 28)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 18))
                .keyboardType(keyboardType)
                .disabled(disabled)
                .autocapitalization(.none)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.white))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.gray.opacity(0.8), lineWidth: 1.2)
        )
    }
}

struct CustomSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    @Binding var showPassword: Bool
    var disabled: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 21, weight: .medium))
                .foregroundColor(Color(hex: "174EA6"))
                .frame(width: 28)
            
            if showPassword {
                TextField(placeholder, text: $text)
                    .font(.system(size: 18))
                    .keyboardType(.numberPad)
                    .disabled(disabled)
                    .onChange(of: text) { newValue in
                        if newValue.count > 4 { text = String(newValue.prefix(4)) }
                    }
            } else {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 18))
                    .keyboardType(.numberPad)
                    .disabled(disabled)
                    .onChange(of: text) { newValue in
                        if newValue.count > 4 { text = String(newValue.prefix(4)) }
                    }
            }
            
            
            Button(action: { showPassword.toggle() }) {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 21, weight: .medium))
                    .foregroundColor(Color.gray.opacity(0.75))
            }
            .disabled(disabled)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.white))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.gray.opacity(0.8), lineWidth: 1.2)
        )
    }
}

struct PrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var disabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                }
                
                Text(title)
                    .font(.system(size: 21, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 19)
            .background(
                    RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "0788B9"))
            )
            .shadow(
                color: disabled ? .clear : Color(hex: "0788B9").opacity(0.25),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .disabled(disabled)
        .animation(.easeInOut(duration: 0.2), value: disabled)
    }
}

struct BiometricButton: View {
    var disabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: BiometricHelper.getBiometricType() == .faceID ? "faceid" : "touchid")
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(Color(hex: "0788B9"))
                        .shadow(color: Color(hex: "0788B9").opacity(0.3), radius: 8, x: 0, y: 4)
                )
        }
        .disabled(disabled)
        .opacity(disabled ? 0.6 : 1.0)
    }
}
#Preview {
    LoginView()
        .environmentObject(AuthenticationManager())
}
