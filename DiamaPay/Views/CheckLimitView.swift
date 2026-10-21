import SwiftUI

struct CheckLimitView: View {
    @Environment(\.dismiss) private var dismiss
    var onOpenSettings: () -> Void = {}
    @State private var showSponsors = false
    @State private var showQR = false
    @State private var isLoading = false
    @State private var hasLoaded = false
    @State private var errorMessage: String?
    @State private var limitSummary: LimitSummary?
    @State private var limitDetails: [LimitDetail] = []
    @State private var expandedCards: Set<Int> = []

    private let accent = Color(hex: "174EA6")

    var body: some View {
        VStack(spacing: 0) {
            DiamaPayHeader(title: "Limits", headerColor: accent)
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        globalDailyLimitCard
                        sectionTitle
                        if isLoading {
                            ProgressView("Loading limits...")
                                .tint(accent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        } else if let errorMessage {
                            VStack(spacing: 12) {
                                Text(errorMessage)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                Button("Try Again", action: loadWalletLimits)
                                    .tint(accent)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        } else if hasLoaded && limitDetails.isEmpty {
                            Text("No limits configured")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 2)
                        } else {
                            ForEach(Array(limitDetails.enumerated()), id: \.offset) { index, limit in
                                limitCard(limit, index: index)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 112)
                }
                Button(action: loadWalletLimits) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 25, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 58, height: 58)
                        .background(Color(hex: "0089BC"))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.18), radius: 5, x: 0, y: 3)
                }
                .disabled(isLoading)
                .opacity(isLoading ? 0.5 : 1)
                .accessibilityLabel("Refresh wallet limits")
                .padding(.trailing, 16)
                .padding(.bottom, 42)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "F5F5F5").ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AppBottomBar(
                onSponsors: { showSponsors = true },
                onQR: { showQR = true },
                onLimits: loadWalletLimits,
                onSettings: {
                    dismiss()
                    onOpenSettings()
                },
                selectedTab: "Limits",
                onHome: { dismiss() }
            )
        }
        .background {
            NavigationLink("", destination: SponsoringWalletListView(), isActive: $showSponsors)
                .hidden()
            NavigationLink("", destination: QRPaymentView(), isActive: $showQR)
                .hidden()
        }
        .navigationBarHidden(true)
        .onAppear {
            if !hasLoaded && errorMessage == nil { loadWalletLimits() }
        }
    }

    private var sectionTitle: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color(hex: "0089BC"))
                .frame(width: 4, height: 26)
            Text("Limits by transaction")
                .font(.system(size: 19, weight: .bold))
                .foregroundColor(accent)
        }
        .padding(.top, 4)
    }

    private var globalDailyLimitCard: some View {
        VStack(spacing: 0) {
            Text("Global Daily Limit")
                .font(.system(size: 23, weight: .bold))
                .multilineTextAlignment(.center)
            Rectangle()
                .fill(Color.white.opacity(0.6))
                .frame(width: 62, height: 2)
                .padding(.top, 10)
            Text("All your transactions share this common daily limit.")
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 20)
                .padding(.bottom, 18)
            VStack(spacing: 10) {
                Text("Global Daily Limit")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(0.5)
                    .foregroundColor(.white.opacity(0.8))
                // Match the existing client's summary-field mapping; never substitute
                // the screenshot's sample amount when the API returns no summary.
                Text(globalLimitAmount)
                    .font(.system(size: 30, weight: .bold))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                if !isLoading && limitSummary?.soldeDisponible == nil {
                    Text("Not available")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.vertical, 22)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(spacing: 4) {
                Text("Period")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
                Text(periodText)
                    .font(.system(size: 14, weight: .bold))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "1B63BA"))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.16), radius: 5, x: 0, y: 3)
    }

    private var globalLimitAmount: String {
        guard let amount = limitSummary?.soldeDisponible, amount.isFinite else { return "—" }
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_GM")
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "—"
    }

    private var periodText: String {
        guard let start = nonempty(limitSummary?.debutPeriode),
              let end = nonempty(limitSummary?.finPeriode) else { return "—" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        func parse(_ value: String) -> Date? {
            for format in ["yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd", "dd/MM/yyyy"] {
                formatter.dateFormat = format
                if let date = formatter.date(from: value) { return date }
            }
            let iso = ISO8601DateFormatter()
            if let date = iso.date(from: value) { return date }
            iso.formatOptions.insert(.withFractionalSeconds)
            return iso.date(from: value)
        }
        guard let startDate = parse(start), let endDate = parse(end) else { return "\(start) - \(end)" }
        formatter.dateFormat = "yyyy"
        let sameYear = formatter.string(from: startDate) == formatter.string(from: endDate)
        formatter.dateFormat = sameYear ? "dd/MM" : "dd/MM/yyyy"
        let startLabel = formatter.string(from: startDate)
        formatter.dateFormat = "dd/MM/yyyy"
        return "\(startLabel) - \(formatter.string(from: endDate))"
    }

    private func limitCard(_ limit: LimitDetail, index: Int) -> some View {
        let expanded = expandedCards.contains(index)
        let currency = nonempty(limit.currencyCode) ?? nonempty(limitSummary?.devise)
        return VStack(alignment: .leading, spacing: 14) {
            Text(nonempty(limit.operationName) ?? "Transaction \(nonempty(limit.processingCode) ?? "—")")
                .font(.headline)
                .foregroundColor(accent)
            detail("Processing code", limit.processingCode)
            Divider()
            if let percentage = limit.pourcentageUtilisationJour, percentage.isFinite {
                detail("Daily usage", String(format: "%.1f%%", percentage))
                // The label retains the reported percentage, including values over 100%.
                // Only the visual bar is constrained to its valid range.
                ProgressView(value: min(max(percentage, 0), 100), total: 100)
                    .tint(accent)
                    .accessibilityLabel("Daily limit usage")
                    .accessibilityValue(String(format: "%.1f percent", percentage))
            } else {
                detail("Daily usage", nil)
            }
            detail("Daily limit", money(limit.limiteJournaliere, currency: currency))
            detail("Used today", money(limit.consommeAujourdhui, currency: currency))
            detail("Remaining today", money(limit.restantAujourdhui, currency: currency))
            detail("Transactions today", limit.nombreTransactionsJour.map { String($0) })
            // These are strings in the backend DTO. Display the bank's values without
            // guessing their code meanings or deriving eligibility from usage alone.
            detail("Can transact", limit.peutTransacter)
            detail("Alert level", limit.niveauAlerte)
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if expanded {
                        expandedCards.remove(index)
                    } else {
                        expandedCards.insert(index)
                    }
                }
            } label: {
                HStack {
                    Text(expanded ? "Hide details" : "View details")
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                }
            }
            .tint(accent)
            .accessibilityValue(expanded ? "Expanded" : "Collapsed")
            if expanded {
                Divider()
                detail("Minimum per transaction", money(limit.montantMinimum, currency: currency))
                detail("Maximum per transaction", money(limit.montantMaximum, currency: currency))
                detail("Period type", limit.typePeriode)
                detail("Period limit", money(limit.limitePeriode, currency: currency))
                detail("Used this period", money(limit.consommePeriode, currency: currency))
                detail("Remaining this period", money(limit.restantPeriode, currency: currency))
                detail("Period starts", limit.debutPeriode)
                detail("Period ends", limit.finPeriode)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: "E0E5EC"), lineWidth: 1))
    }

    private func detail(_ title: String, _ value: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(nonempty(value) ?? "Not provided")
                .font(.subheadline)
                .foregroundColor(Color(hex: "303949"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private func nonempty(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        return value
    }

    private func money(_ amount: Double?, currency: String?) -> String? {
        guard let amount, amount.isFinite else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        guard let number = formatter.string(from: NSNumber(value: amount)) else { return nil }
        guard let code = nonempty(currency) else { return number }
        return "\(number) \(code == "270" ? "GMD" : code)"
    }

    private func loadWalletLimits() {
        guard !isLoading else { return }
        let user = UserDataManager.shared
        let wallet = nonempty(user.getWalletNumber())
        let phone = nonempty(user.getPhoneNumber())
        guard wallet != nil || phone != nil else {
            errorMessage = "Your wallet details are missing. Please sign in again."
            return
        }
        isLoading = true
        errorMessage = nil
        limitSummary = nil
        limitDetails = []
        expandedCards.removeAll()

        var request = RequestGetWalletLimits()
        request.walletNumber = wallet
        request.phoneNumber = phone
        request.bank = nonempty(user.getBankCode()) ?? "00100"
        APIClient.shared.getWalletLimits(request: request) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let response):
                    guard response.isSuccessful else {
                        errorMessage = nonempty(response.message) ?? "Unable to load wallet limits. Please try again."
                        return
                    }
                    limitSummary = response.summary
                    limitDetails = response.limits ?? []
                    hasLoaded = true
                case .failure(let error):
                    errorMessage = (error as? APIError)?.message ?? "Unable to load wallet limits. Please check your connection and try again."
                }
            }
        }
    }
}
