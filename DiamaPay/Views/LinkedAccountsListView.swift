//
//  LinkedAccountsListView.swift
//  DiamaPay
//
//  Created by Bits on 30/9/2025.
//

import SwiftUI

struct LinkedAccountsListView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var accounts: [Account] = []
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showPinDialog = false
    @State private var verifiedPin: String = ""
    
    private let userDataManager = UserDataManager.shared
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                DiamaPayHeader()

                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blueH))
                        .scaleEffect(1.5)
                    Text("Chargement en cours...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.top, 16)
                    Spacer()
                } else if accounts.isEmpty {
                    emptyStateView
                } else {
                    accountsContent
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            showPinDialog = true
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showPinDialog) {
            PinDialogViewA(
                onPinVerified: { pin in
                    verifiedPin = pin
                    userDataManager.savePinForAPI(pin)
                    showPinDialog = false
                    fetchLinkedAccounts()
                },
                onCancel: {
                    showPinDialog = false
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }

    
    private var titleCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blueH)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            VStack(spacing: 4) {
                Text("Comptes bancaires liés")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Rectangle()
                    .fill(.white)
                    .frame(width: 80, height: 3)
            }
            .padding(.vertical, 15)
            .padding(.horizontal, 8)
        }
        .fixedSize(horizontal: false, vertical: true)  // Add this!
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    private var accountsContent: some View {
        VStack(spacing: 0) {
            titleCard
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(accounts) { account in
                        AccountCard(
                            account: account,
                            onTap: {
                                if verifiedPin.isEmpty {
                                    showPinDialog = true
                                } else {
                                    fetchAccountBalance(account)
                                }
                            }
                        )
                    }
                }
                .padding(16)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 0) {
            titleCard
            
            Spacer()
            
            Image(systemName: "building.columns")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Aucun compte bancaire lié trouvé")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 16)
                .padding(.horizontal, 32)
            
            Spacer()
        }
    }
    
    private func fetchLinkedAccounts() {
        isLoading = true
        
        var request = RequestListLinkedAcc()
        request.source = "W"
        request.walletNumber = userDataManager.getWalletNumber()
        request.phoneNumber = userDataManager.getPhoneNumber()
        request.bank = userDataManager.getBankCode().isEmpty ? "00100" : userDataManager.getBankCode()
        request.entityId = UserDataManager.shared.getUserCode()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyMMdd"
        let datePrefix = dateFormatter.string(from: Date())
        let randomDigits = String(format: "%06d", Int.random(in: 0...999999))
        request.requestId = datePrefix + randomDigits
        
        let fullDateFormatter = DateFormatter()
        fullDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        request.requestDate = fullDateFormatter.string(from: Date())
        
        APIClient.shared.getLinkedAccounts(request: request) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.respCode == "000" || response.respCode == "00" {
                        self.parseAccounts(response)
                    } else {
                        self.showError(response.message ?? "Erreur lors de la récupération des comptes")
                    }
                case .failure(let error):
                    if let apiError = error as? APIError {
                        self.showError(apiError.message)
                    } else {
                        self.showError("Erreur de connexion: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func parseAccounts(_ response: JResponseService) {
        accounts.removeAll()
        
        guard let resultList = response.result else { return }
        
        for item in resultList {
            guard let dict = item as? [String: Any] else { continue }
            
            var account = Account()
            account.accountNumber = dict["accountNumber"] as? String ?? ""
            account.accountHolder = dict["accountHolder"] as? String ?? ""
            account.accountName = dict["accountName"] as? String ?? ""
            account.bankCode = dict["bankCode"] as? String ?? ""
            account.bankName = dict["bankName"] as? String ?? ""
            account.accountType = dict["accountType"] as? String ?? ""
            account.currency = dict["currency"] as? String ?? "GNF"
            account.balance = dict["balance"] as? String ?? "0.00"
            
            if !account.accountNumber.isEmpty {
                accounts.append(account)
            }
        }
    }
    
    private func fetchAccountBalance(_ account: Account) {
        guard let index = accounts.firstIndex(where: { $0.id == account.id }) else { return }
        
        isLoading = true
        let clientId = userDataManager.getUserCode()
        
        APIClient.shared.getAccountBalance(accountNumber: account.accountNumber, clientId: clientId) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.code == "000" || response.code == "00" {
                        if let balanceInfo = response.data {
                            self.accounts[index].balance = balanceInfo.availableBalance
                            self.accounts[index].currency = balanceInfo.currency
                            self.showSuccess("Solde mis à jour: \(balanceInfo.availableBalance) \(balanceInfo.currency)")
                        }
                    } else {
                        self.showError(response.message ?? "Impossible de récupérer le solde")
                    }
                case .failure(let error):
                    if let apiError = error as? APIError {
                        self.showError(apiError.message)
                    } else {
                        self.showError("Échec de la connexion")
                    }
                }
            }
        }
    }
    
    private func showError(_ message: String) {
        alertTitle = "Erreur"
        alertMessage = message
        showAlert = true
    }
    
    private func showSuccess(_ message: String) {
        alertTitle = "Succès"
        alertMessage = message
        showAlert = true
    }
}

struct AccountCard: View {
    let account: Account
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
              
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.accountHolder)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(account.accountNumber)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                       
                        
                        if !account.accountType.isEmpty {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(account.accountType)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatBalance())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.greenH)
                    
                    Text("Solde")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatBalance() -> String {
        // Show **** for zero or invalid amounts
        guard let amount = Double(account.balance), amount > 0 else {
            return "****"
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.maximumFractionDigits = 0
        
        let formatted = formatter.string(from: NSNumber(value: amount)) ?? "***"
        return "\(formatted) \(account.currency)"
    }
}

struct PinDialogViewA: View {
    let onPinVerified: (String) -> Void
    let onCancel: () -> Void
    
    @State private var pin: String = ""
    @State private var isVerifying = false
    @State private var errorMessage: String = ""
    
    private let userDataManager = UserDataManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blueH)
                    
                    Text("Vérification du code PIN")
                        .font(.system(size: 20, weight: .bold))
                    
                    Text("Entrez votre code PIN pour continuer")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    SecureField("Code PIN", text: $pin)
                        .keyboardType(.numberPad)
                        .font(.system(size: 16, weight: .medium))
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .onChange(of: pin) { newValue in
                                if newValue.count > 4 {
                                    pin = String(newValue.prefix(4))
                                }
                            }
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(errorMessage.isEmpty ? Color.gray.opacity(0.3) : Color.red, lineWidth: 1)
                        )
                        .padding(.horizontal, 32)
                    
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
                            Text("Vérifier")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(pin.count >= 4 ? Color.blueH : Color.gray)
                    .cornerRadius(10)
                    .padding(.horizontal, 32)
                    .disabled(pin.count < 4 || isVerifying)
                    
                    Spacer()
                }
            }
            .navigationBarItems(leading: Button("Annuler") { onCancel() })
            .navigationBarTitle("", displayMode: .inline)
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
            onPinVerified(verifiedPin)
        } onFailure: { message in
            isVerifying = false
            errorMessage = message
            pin = ""
        }
    }
    
}

struct LinkedAccountsListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LinkedAccountsListView()
        }
    }
}
