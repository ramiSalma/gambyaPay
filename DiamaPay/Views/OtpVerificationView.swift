//
//  OtpVerificationView.swift
//  DiamaPay
//
//  Created by Bits on 18/9/2025.
//

import SwiftUI

struct OtpVerificationView: View {
    @ObservedObject private var localization = AppLanguageStore.shared
    let phoneNumber: String
    let deviceId: String
    
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var otp = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    
    var body: some View {
        VStack(spacing: 30) {
            Image("logo_diama")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .padding(.top, 50)
            
            Text(AppStrings.verifiezVotreAppareil)
                .font(.title3)
                .bold()
            
            Text(AppStrings.entrezLeCodeOtpEnvoyeAValue(String(describing: maskedPhoneNumber)))
                .font(.subheadline)
                .foregroundColor(.gray)
            
            // OTP input field
            TextField("------", text: $otp)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .font(.system(size: 24, weight: .medium, design: .monospaced))
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                .padding(.horizontal, 50)
            
            Button(action: verifyOtp) {
                if isLoading {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(AppStrings.verifier)
                        .bold()
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color.blueH)
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding(.horizontal, 30)
            .disabled(isLoading || otp.count != 6)
            
            Spacer()
        }
        .alert(AppStrings.error, isPresented: $showAlert) {
            Button(AppStrings.ok, role: .cancel) { }
        } message: {
            Text(AppStrings.option(alertMessage))
        }
        .onAppear {
            // ✅ DEBUG: Log values when view appears
            print("🔍 OtpVerificationView appeared")
            print("   phoneNumber: [\(phoneNumber)]")
            print("   deviceId: [\(deviceId)]")
        }
    }
    
    private var maskedPhoneNumber: String {
        if phoneNumber.count > 4 {
            let start = phoneNumber.prefix(3)
            let end = phoneNumber.suffix(3)
            return "\(start)****\(end)"
        }
        return phoneNumber
    }
    
    private func verifyOtp() {
        guard otp.count == 6 else { return }
        
        // ✅ DEBUG: Log values before creating request
        print("🔍 verifyOtp() called")
        print("   self.phoneNumber: [\(self.phoneNumber)]")
        print("   self.deviceId: [\(self.deviceId)]")
        print("   self.otp: [\(self.otp)]")
        
        isLoading = true
        let request = OtpVerificationRequest(phoneNumber: self.phoneNumber, otp: self.otp, deviceId: self.deviceId)
        
        // ✅ DEBUG: Log request after creation
        print("🔍 Request created:")
        print("   request.phoneNumber: [\(request.phoneNumber)]")
        print("   request.deviceId: [\(request.deviceId)]")
        print("   request.otp: [\(request.otp)]")
        
        APIClient.shared.verifyOtp(request: request) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let authResponse):
                    if authResponse.success == true, let token = authResponse.token {
                        // Save user data
                        UserDataManager.shared.saveUserData(from: authResponse)
                        
                        // Update API client token
                        APIClient.shared.updateToken(token)
                        
                        // Log user in through AuthManager
                        authManager.login()
                        
                        // Dismiss OTP view to return to login
                        dismiss()
                    } else {
                        alertMessage = authResponse.message ?? AppStrings.otpVerificationFailed
                        showAlert = true
                    }

                case .failure(let error):
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
}
