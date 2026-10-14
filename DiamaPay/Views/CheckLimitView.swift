//
//  CheckLimitView.swift
//  DiamaPayÌ
//

import SwiftUI

struct CheckLimitView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Erreur"
    
    @State private var limitSummary: LimitSummary?
    @State private var limitDetails: [LimitDetail] = []
    @State private var expandedCards: Set<String> = []
    
    private let userDataManager = UserDataManager.shared
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                DiamaPayHeader()

                if isLoading {
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.20, green: 0.40, blue: 0.80)))
                            .scaleEffect(1.5)
                        
                        Text("Chargement des limites...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Combined Summary Card
                            if let summary = limitSummary {
                                combinedSummaryCard(summary: summary)
                            }
                            
                            // Section Title
                            if !limitDetails.isEmpty {
                                sectionTitle
                                
                                // Individual Limit Cards
                                ForEach(sortedLimitDetails(), id: \.processingCode) { limit in
                                    limitDetailCard(limit: limit)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 80)
                    }
                }
            }
            
            // Floating Refresh Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        loadWalletLimits()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .semibold))
                            .frame(width: 56, height: 56)
                            .background(Color(red: 0.20, green: 0.40, blue: 0.80))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            //print("🔵 CheckLimitView appeared - loading limits...")
            loadWalletLimits()
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    

    
    // MARK: - Combined Summary Card
    private func combinedSummaryCard(summary: LimitSummary) -> some View {
        let prfidLimit = summary.soldeDisponible ?? 0.0
        let prfidConsumed = summary.totalConsommeJour ?? 0.0
        let prfidRemaining = max(prfidLimit - prfidConsumed, 0)
        let prfidPercentage = prfidLimit > 0 ? (prfidConsumed / prfidLimit) * 100.0 : 0.0
        
        let cardColor = getCardColor(percentage: prfidPercentage)
        let alertText = getAlertMessage(percentage: prfidPercentage)
        
        return VStack(alignment: .leading, spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardColor)
                    .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 4)
                
                VStack(spacing: 20) {
                    // Title
                    VStack(spacing: 8) {
                        Text("Limite Journalière Globale")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.7))
                            .frame(width: 60, height: 2)
                    }
                    
                    // Alert Message
                    Text(alertText)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                    
                    // Progress Bar
                    VStack(alignment: .trailing, spacing: 8) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(Color.white.opacity(0.2))
                                
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(Color.white)
                                    .frame(width: geometry.size.width * CGFloat(min(prfidPercentage, 100)) / 100)
                            }
                        }
                        .frame(height: 10)
                        
                        Text(String(format: "%.1f%%", prfidPercentage))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    // Stats Grid
                    HStack(spacing: 0) {
                        // Limit
                        statColumn(
                            title: "LIMITE",
                            value: formatAmountShort(prfidLimit),
                            subtitle: "GNF"
                        )
                        
                        // Consumed
                        statColumn(
                            title: "CONSOMMÉ",
                            value: formatAmountShort(prfidConsumed),
                            subtitle: "GNF"
                        )
                        
                        // Remaining
                        statColumn(
                            title: "DISPONIBLE",
                            value: formatAmountShort(prfidRemaining),
                            subtitle: "GNF"
                        )
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.15))
                    )
                    
                    // Bottom Info Row
                    HStack {
                        // Transactions
                        HStack(spacing: 4) {
                            Text("\(summary.totalTransactionsJour ?? 0)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("transaction(s)")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        // Period
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Période")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("\(summary.debutPeriode ?? "") - \(summary.finPeriode ?? "")")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                }
                .padding(20)
            }
        }
    }
    
    private func statColumn(title: String, value: String, subtitle: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white.opacity(0.8))
                .kerning(0.5)
            
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(subtitle)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Section Title
    private var sectionTitle: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color(red: 0.20, green: 0.40, blue: 0.80))
                .frame(width: 4, height: 24)
            
            Text("Détails par Opération")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(red: 0.13, green: 0.13, blue: 0.13))
                .kerning(0.2)
            
            Spacer()
        }
        .padding(.top, 24)
        .padding(.bottom, 12)
    }
    
    // MARK: - Limit Detail Card (UPDATED TO MATCH ANDROID)
    private func limitDetailCard(limit: LimitDetail) -> some View {
        let percentage = limit.pourcentageUtilisationJour ?? 0.0
        let consumed = limit.consommeAujourdhui ?? 0.0
        let remaining = limit.restantAujourdhui ?? 0.0
        let isExpanded = expandedCards.contains(limit.processingCode ?? "")
        let displayName = ProcessingCodeMapper.getOperationInfo(limit.processingCode ?? "").name
        
        return VStack(alignment: .leading, spacing: 0) {
            cardHeader(displayName: displayName)
            gradientDivider()
            cardMainContent(limit: limit, percentage: percentage, consumed: consumed, remaining: remaining, isExpanded: isExpanded)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
    
    private func cardHeader(displayName: String) -> some View {
        HStack(spacing: 12) {
            Text(displayName)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color.black.opacity(0.5))
            Spacer()
        }
        .padding(20)
        .background(Color.white)
    }
    
    private func gradientDivider() -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blueH,
                        Color.blueH.opacity(0.3)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 2)
    }
    
    private func cardMainContent(limit: LimitDetail, percentage: Double, consumed: Double, remaining: Double, isExpanded: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if percentage > 0 {
                usageProgressSection(percentage: percentage)
            }
            
            statsGrid(limit: limit, consumed: consumed, remaining: remaining)
            
            if (limit.nombreTransactionsJour ?? 0) > 0 {
                transactionCountInfo(count: limit.nombreTransactionsJour ?? 0)
            }
            
            expandButton(limit: limit, isExpanded: isExpanded)
            
            if isExpanded {
                expandableSection(limit: limit)
            }
        }
        .padding(10)
        .background(Color.white)
    }
    
    private func usageProgressSection(percentage: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Utilisation")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(red: 0.46, green: 0.46, blue: 0.46))
                Spacer()
                Text(String(format: "%.1f%%", percentage))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(getProgressColor(percentage: percentage))
            }
            .padding(.bottom, 8)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.91, green: 0.96, blue: 0.91))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(getProgressColor(percentage: percentage))
                        .frame(width: geometry.size.width * CGFloat(min(percentage, 100)) / 100)
                }
            }
            .frame(height: 8)
        }
        .padding(5)
        .padding(.bottom, 16)
    }
    
    private func statsGrid(limit: LimitDetail, consumed: Double, remaining: Double) -> some View {
        HStack(spacing: 0) {
            statsColumn(title: "LIMITE", value: formatAmountShort(limit.limiteJournaliere), color: Color(red: 0.13, green: 0.13, blue: 0.13))
            statsColumn(title: "CONSOMMÉ", value: consumed > 0 ? formatAmountShort(consumed) : "0", color: consumed > 0 ? Color(red: 0.957, green: 0.263, blue: 0.212) : Color(red: 0.13, green: 0.13, blue: 0.13))
            statsColumn(title: "DISPONIBLE", value: formatAmountShort(remaining), color: remaining > 0 ? Color(red: 0.298, green: 0.686, blue: 0.314) : Color(red: 0.957, green: 0.263, blue: 0.212))
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 4).fill(Color(red: 0.976, green: 0.976, blue: 0.976)))
    }
    
    private func statsColumn(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Color(red: 0.62, green: 0.62, blue: 0.62))
                .kerning(0.1)
            
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text("GNF")
                .font(.system(size: 9))
                .foregroundColor(Color(red: 0.46, green: 0.46, blue: 0.46))
        }
        .frame(maxWidth: .infinity)
    }
    
    private func transactionCountInfo(count: Int) -> some View {
        HStack {
            Spacer()
            Text("\(count)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(red: 0.13, green: 0.13, blue: 0.13))
            Text(" transaction(s)")
                .font(.system(size: 12))
                .foregroundColor(Color(red: 0.46, green: 0.46, blue: 0.46))
            Spacer()
        }
        .padding(.top, 12)
    }
    
    private func expandButton(limit: LimitDetail, isExpanded: Bool) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                if isExpanded {
                    expandedCards.remove(limit.processingCode ?? "")
                } else {
                    expandedCards.insert(limit.processingCode ?? "")
                }
            }
        }) {
            HStack {
                Spacer()
                Text("Voir plus de détails")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.black.opacity(0.5))
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundColor(Color.black.opacity(0.5))
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.top, 8)
        }
    }
    
    private func expandableSection(limit: LimitDetail) -> some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color(red: 0.88, green: 0.88, blue: 0.88))
                .frame(height: 1)
                .padding(.bottom, 12)
            
            Text("INFORMATIONS DÉTAILLÉES")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(red: 0.62, green: 0.62, blue: 0.62))
                .kerning(0.1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 12)
            
            expandableDetails(limit: limit)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
        .background(Color(red: 0.98, green: 0.98, blue: 0.98))
    }
    
    private func expandableDetails(limit: LimitDetail) -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Montant par transaction")
                    .font(.system(size: 11))
                    .foregroundColor(Color(red: 0.62, green: 0.62, blue: 0.62))
                
                Text("\(formatAmount(limit.montantMinimum)) - \(formatAmount(limit.montantMaximum))")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(red: 0.13, green: 0.13, blue: 0.13))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .padding(.bottom, 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Limite mensuelle")
                    .font(.system(size: 11))
                    .foregroundColor(Color(red: 0.62, green: 0.62, blue: 0.62))
                
                let consumedPeriod = limit.consommePeriode ?? 0.0
                Text(consumedPeriod > 0 ?
                    "\(formatAmount(consumedPeriod)) utilisé sur \(formatAmount(limit.limitePeriode))" :
                    formatAmount(limit.limitePeriode))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(red: 0.13, green: 0.13, blue: 0.13))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        }
    }
    
    // MARK: - API Call
    private func loadWalletLimits() {
        isLoading = true
        
        let walletNumber = userDataManager.getWalletNumber()
        let phoneNumber = userDataManager.getPhoneNumber()
        
        
        guard !walletNumber.isEmpty else {
            isLoading = false
            showErrorAlert("Numéro de wallet non trouvé")
            return
        }
        
        var request = RequestGetWalletLimits()
        request.walletNumber = walletNumber
        request.phoneNumber = phoneNumber
        request.bank = "00100"
                
        APIClient.shared.getWalletLimits(request: request) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    
                    if response.respCode == "000" {
                        self.limitSummary = response.summary
                        self.limitDetails = response.limits ?? []
                        
                
                        if let summary = response.summary {
                      
                        }
                    } else {
                        self.showErrorAlert(response.message ?? "Erreur lors du chargement des limites")
                    }
                    
                case .failure(let error):
                    if let apiError = error as? APIError {
                        self.showErrorAlert(apiError.message)
                    } else {
                        self.showErrorAlert("Erreur de connexion: \(error.localizedDescription)")
                    }
                }
                
            }
        }
    }
    
    // MARK: - Helper Methods
    private func sortedLimitDetails() -> [LimitDetail] {
        var sorted = limitDetails.filter { !shouldHideOperation($0.processingCode ?? "") }
        sorted.sort { (a, b) in
            let priorityA = getOperationPriority(a.processingCode ?? "")
            let priorityB = getOperationPriority(b.processingCode ?? "")
            if priorityA != priorityB {
                return priorityA < priorityB
            }
            return (a.processingCode ?? "") < (b.processingCode ?? "")
        }
        return sorted
    }
    
    // UPDATED: Match Android exactly - code 49 IS hidden, codes 44 and 48 are visible
    private func shouldHideOperation(_ processingCode: String) -> Bool {
        let hiddenCodes = ["32", "23", "33", "34", "35", "49", "46", "47", "51", "70", "71", "72", "73", "74", "91", "92", "98", "99", "17"]
        return hiddenCodes.contains(processingCode)
    }
    
    private func getOperationPriority(_ processingCode: String) -> Int {
        switch processingCode {
        case "41": return 1  // Transfert d'argent (Wallet à Wallet)
        case "45": return 2  // Recharge wallet (Retrait espèces)
        case "43": return 3  // Mise à disposition (Dépôt espèces)
        case "42": return 4  // Vers ma banque (Retrait agence)
        case "11": return 5  // Dépôt agence
        case "44": return 6  // Paiement QR (VISIBLE)
        case "48": return 8  // Crédit QR GIP (VISIBLE)
        case "30": return 9  // Paiement marchand
        case "50": return 10 // Achat de crédit
        case "40": return 11 // Transfert bancaire
        case "60": return 12 // Retrait ATM
        case "31": return 13 // Consultation solde
        case "01": return 14 // Activation (Retrait d'espèces)
        case "12": return 15 // Déblocage
        case "22": return 16 // Retrait agent (Ajustement)
        case "18": return 17 // Annulation
        default: return 100
        }
    }
    
    private func getCardColor(percentage: Double) -> Color {
        if percentage >= 95 {
            return Color(red: 0.827, green: 0.184, blue: 0.184) // #D32F2F
        } else if percentage >= 80 {
            return Color(red: 0.780, green: 0.216, blue: 0.235) // #C6373C (Android red)
        } else if percentage >= 50 {
            return Color(red: 0.961, green: 0.620, blue: 0.302) // #F59E4D
        } else {
            return Color(red: 0.20, green: 0.40, blue: 0.80) // Default blue
        }
    }
    
    private func getAlertMessage(percentage: Double) -> String {
        if percentage >= 95 {
            return "Limite journalière atteinte. Aucune transaction supplémentaire possible jusqu'à demain."
        } else if percentage >= 80 {
            return "Attention: Vous approchez de votre limite journalière globale."
        } else {
            return "Toutes vos opérations partagent cette limite quotidienne commune."
        }
    }
    
    private func getProgressColor(percentage: Double) -> Color {
        if percentage >= 80 {
            return Color(red: 0.957, green: 0.263, blue: 0.212) // #F44336
        } else if percentage >= 50 {
            return Color(red: 1.0, green: 0.596, blue: 0.0) // #FF9800
        } else {
            return Color(red: 0.298, green: 0.686, blue: 0.314) // #4CAF50
        }
    }
    
    private func formatAmount(_ amount: Double?) -> String {
        guard let amount = amount else { return "0 GNF" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.maximumFractionDigits = 0
        return (formatter.string(from: NSNumber(value: amount)) ?? "0") + " GNF"
    }
    
    private func formatAmountShort(_ amount: Double?) -> String {
        guard let amount = amount else { return "0" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
    
    private func showErrorAlert(_ message: String) {
        alertTitle = "Erreur"
        alertMessage = message
        showAlert = true
    }
}
