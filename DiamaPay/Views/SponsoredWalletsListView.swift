//
//  SponsoredWalletsListView.swift
//  DiamaPay
//
//

import SwiftUI

struct SponsoredWalletsListView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var sponsoredWallets: [SponsoredWallet] = []
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showUpdateDialog = false
    @State private var selectedWallet: SponsoredWallet?
    @State private var showPinDialog = false
    @State private var showUnlinkAlert = false
    @State private var pinDialogAction: PinDialogAction = .unlink
    
    private let userDataManager = UserDataManager.shared
    
    enum PinDialogAction {
        case unlink
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                DiamaPayHeader(title: "Portefeuilles parrainés", headerColor: Color(hex: "174EA6"))

                if isLoading {
                    loadingView
                } else {
                    contentView
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AppBottomBar(onSponsors: {}, onQR: {}, onLimits: {}, onSettings: {})
        }
        .navigationBarHidden(true)
        .onAppear {
            loadSponsoredWallets()
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .alert("Dissocier le portefeuille", isPresented: $showUnlinkAlert) {
            Button("Annuler", role: .cancel) { }
            Button("Dissocier", role: .destructive) {
                pinDialogAction = .unlink
                showPinDialog = true
            }
        } message: {
            if let wallet = selectedWallet {
                Text("Voulez-vous vraiment dissocier le portefeuille de \(wallet.userNameSponsored)?\n\nCette action est irréversible.")
            }
        }
        .sheet(isPresented: $showUpdateDialog) {
            if let wallet = selectedWallet {
                UpdateSponsoredWalletView(
                    wallet: wallet,
                    onSuccess: {
                        showUpdateDialog = false
                        loadSponsoredWallets()
                    }
                )
            }
        }
        .overlay(pinDialogOverlay)
    }
    
    // MARK: - PIN Dialog Overlay
    private var pinDialogOverlay: some View {
        Group {
            if showPinDialog, let wallet = selectedWallet {
                PinDialogView(
                    isPresented: $showPinDialog,
                    title: pinDialogAction == .unlink ? "Dissocier le portefeuille" : "",
                    message: pinDialogAction == .unlink ? "Entrez votre code PIN pour confirmer" : "",
                    onConfirm: { pin in
                        showPinDialog = false
                        if pinDialogAction == .unlink {
                            performUnlink(wallet: wallet, pin: pin)
                        }
                    }
                )
            }
        }
    }

    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "174EA6")))
            
            Text("Chargement...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Content View
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 14) {
                if sponsoredWallets.isEmpty {
                    emptyStateView
                } else {
                    // Wallets List
                    VStack(spacing: 12) {
                        ForEach(sponsoredWallets, id: \.id) { wallet in
                            SponsoredWalletCard(
                                wallet: wallet,
                                onUpdate: {
                                    selectedWallet = wallet
                                    showUpdateDialog = true
                                },
                                onUnlink: {
                                    selectedWallet = wallet
                                    showUnlinkConfirmation(for: wallet)
                                }
                            )
                        }
                    }
                }
                
                // Add Button
                NavigationLink(destination: SponsorWalletView()) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                        Text("Sponsoriser un portefeuille")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color(hex: "174EA6"))
                    .cornerRadius(14)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 88)
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "wallet.pass")
                .font(.system(size: 42))
                .foregroundColor(Color(hex: "174EA6").opacity(0.75))
                .padding(.top, 24)
            
            Text("Aucun portefeuille parrainé")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            Text("Vous n'avez sponsorisé aucun portefeuille pour le moment")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.06), lineWidth: 1))
        .shadow(color: .black.opacity(0.07), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Load Sponsored Wallets
    private func loadSponsoredWallets() {
        isLoading = true
        
        var request = RequestListSponsoredWallets()
        request.source = "P"
        request.phoneNumber = userDataManager.getPhoneNumber()
        request.bank = "00100"
        request.pin = userDataManager.getPinForAPI()
        
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
        
        APIClient.shared.getSponsoredWallets(request: request) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.respCode == "000" {
                        self.processSponsoredWallets(response)
                    } else {
                        self.showError("Erreur", response.message ?? "Impossible de charger les portefeuilles")
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
    
    private func processSponsoredWallets(_ response: JResponseService) {
        sponsoredWallets.removeAll()
        
        guard let resultList = response.result else { return }
        
        for sponsorData in resultList {
            guard let dict = sponsorData as? [String: Any] else { continue }
            
            var wallet = SponsoredWallet()
            wallet.walletNumber = dict["walletNumber"] as? String ?? ""
            wallet.walletNumberSponsored = dict["walletNumberSponsored"] as? String ?? ""
            wallet.userName = dict["userName"] as? String ?? ""
            wallet.userNameSponsored = dict["userNameSponsored"] as? String ?? "Non spécifié"
            wallet.phoneNumber = dict["phoneNumber"] as? String ?? ""
            wallet.phoneNumberSponsored = dict["phoneNumberSponsored"] as? String ?? ""
            
            // Handle dailyLimit
            if let dailyLimitInt = dict["dailyLimit"] as? Int {
                wallet.dailyLimit = String(format: "%.0f", Double(dailyLimitInt))
            } else if let dailyLimitDouble = dict["dailyLimit"] as? Double {
                wallet.dailyLimit = String(format: "%.0f", dailyLimitDouble)
            } else if let dailyLimitStr = dict["dailyLimit"] as? String {
                wallet.dailyLimit = dailyLimitStr
            } else {
                wallet.dailyLimit = "0"
            }
            
            // Handle monthlyLimit
            if let monthlyLimitInt = dict["monthlyLimit"] as? Int {
                wallet.monthlyLimit = String(format: "%.0f", Double(monthlyLimitInt))
            } else if let monthlyLimitDouble = dict["monthlyLimit"] as? Double {
                wallet.monthlyLimit = String(format: "%.0f", monthlyLimitDouble)
            } else if let monthlyLimitStr = dict["monthlyLimit"] as? String {
                wallet.monthlyLimit = monthlyLimitStr
            } else {
                wallet.monthlyLimit = "0" 
            }
            
            wallet.startDate = dict["startDate"] as? String ?? ""
            wallet.endDate = dict["endDate"] as? String ?? ""
            wallet.bankCode = dict["bankCode"] as? String ?? ""
            wallet.bankWording = dict["bankWording"] as? String ?? ""
            wallet.creationTs = dict["creationTs"] as? String ?? ""
            
            if !wallet.walletNumberSponsored.isEmpty {
                sponsoredWallets.append(wallet)
            }
        }
    }
    
    // MARK: - Unlink Confirmation
    private func showUnlinkConfirmation(for wallet: SponsoredWallet) {
        showUnlinkAlert = true
    }
    
    private func performUnlink(wallet: SponsoredWallet, pin: String) {
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
        
        request.pin = pin
        request.bankCode = bankCode
        request.walletNumberSponsored = wallet.walletNumberSponsored
        request.phoneNumberSponsored = wallet.phoneNumberSponsored
        request.bankCodeSponsored = wallet.bankCode.isEmpty ? bankCode : wallet.bankCode
        request.dateStart = wallet.startDate
        request.dateEnd = wallet.endDate
        request.dailyLimit = wallet.dailyLimit.isEmpty ? "10" : wallet.dailyLimit
        request.monthlyLimit = wallet.monthlyLimit.isEmpty ? "120" : wallet.monthlyLimit
        
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
        
        APIClient.shared.unlinkSponsoredWallet(request: request) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.respCode == "000" {
                        self.showSuccess("Portefeuille dissocié avec succès")
                        self.loadSponsoredWallets()
                    } else {
                        self.showError("Erreur", response.message ?? "Échec de la dissociation")
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

// MARK: - Sponsored Wallet Card
struct SponsoredWalletCard: View {
    let wallet: SponsoredWallet
    let onUpdate: () -> Void
    let onUnlink: () -> Void
    
    @State private var showMenu = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with name, phone and menu
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bénéficiaire: \(wallet.userNameSponsored)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "174EA6"))
                    
                    if !wallet.phoneNumberSponsored.isEmpty {
                        Text(wallet.phoneNumberSponsored)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    showMenu = true
                }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(hex: "174EA6"))
                        .frame(width: 32, height: 32)
                }
            }
            
            Divider()
            
            // Limits
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Limite journalière")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(wallet.dailyLimit))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Limite mensuelle")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(wallet.monthlyLimit))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
            }
            
            // Date range
            VStack(alignment: .leading, spacing: 4) {
                Text("Période de validité")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Text(formatDateRange(start: wallet.startDate, end: wallet.endDate))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            // Bank
            if !wallet.bankWording.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Banque")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text(wallet.bankWording)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.06), lineWidth: 1))
        .shadow(color: .black.opacity(0.07), radius: 5, x: 0, y: 2)
        .actionSheet(isPresented: $showMenu) {
            ActionSheet(
                title: Text("Options"),
                buttons: [
                    .default(Text("Mettre à jour")) {
                        onUpdate()
                    },
                    .destructive(Text("Dissocier")) {
                        onUnlink()
                    },
                    .cancel(Text("Annuler"))
                ]
            )
        }
    }
    
    private func formatCurrency(_ amount: String) -> String {
        guard let value = Double(amount), value > 0 else {
            return "Non limité"
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.maximumFractionDigits = 0
        
        return (formatter.string(from: NSNumber(value: value)) ?? amount) + " GNF"
    }
    
    private func formatDateRange(start: String, end: String) -> String {
        var result = ""
        
        if !start.isEmpty && start != "null" {
            result += "Du \(formatDate(start))"
        } else {
            result += "Date de début non spécifiée"
        }
        
        if !end.isEmpty && end != "null" {
            result += " au \(formatDate(end))"
        } else if !start.isEmpty && start != "null" {
            result += " - Sans date de fin"
        }
        
        return result
    }
    
    private func formatDate(_ dateStr: String) -> String {
        let inputFormats = ["yyyyMMdd", "MM-dd-yyyy", "yyyy-MM-dd", "yyyyMMddHHmm"]
        
        for format in inputFormats {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            
            if let date = formatter.date(from: dateStr) {
                let outputFormatter = DateFormatter()
                outputFormatter.dateFormat = "dd/MM/yyyy"
                outputFormatter.locale = Locale(identifier: "fr_FR")
                return outputFormatter.string(from: date)
            }
        }
        
        return dateStr
    }
}

// MARK: - PIN Dialog View
struct PinDialogView: View {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let onConfirm: (String) -> Void
    
    @State private var pin: String = ""
    @State private var showError = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 20) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                SecureField("Code PIN", text: $pin)
                    .keyboardType(.numberPad)
                    .font(.system(size: 16))
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
                
                if showError {
                    Text("Veuillez entrer votre code PIN")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }
                
                HStack(spacing: 12) {
                    Button(action: {
                        isPresented = false
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
                        if pin.isEmpty {
                            showError = true
                        } else {
                            showError = false
                            onConfirm(pin)
                        }
                    }) {
                        Text("Confirmer")
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

struct SponsoredWalletsListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SponsoredWalletsListView()
        }
    }
}
