import SwiftUI

struct RequestSavingBalance: Codable {
    var walletNumber: String
    var phoneNumber: String
    var source: String = "W"
    var bank: String
    var requestId: String
    var requestDate: String
    var entityId: String
}

struct RequestCreditSaving: Codable {
    var walletNumber: String
    var phoneNumber: String
    var source: String = "W"
    var bank: String
    var amount: String
    var currency: String = "270"
    var reason: String
    var requestId: String
    var requestDate: String
    var entityId: String
}

struct RequestDebitSaving: Codable {
    var walletNumber: String
    var phoneNumber: String
    var source: String = "W"
    var bank: String
    var currency: String = "270"
    var amount: String
    var reason: String
    var requestId: String
    var requestDate: String
    var entityId: String
}

private struct SavingsTransaction: Identifiable {
    let id = UUID()
    let date: String
    let reference: String
    let amount: String
    let currency: String
    let sign: String
    let type: String
}

private enum SavingsStyle {
    static let blue = Color(hex: "174EA6")
    static let cyan = Color(hex: "0788B9")
    static let ink = Color(hex: "505A69")
    static let background = Color(hex: "F6F8FC")
}

struct SavingsWalletView: View {
    @State private var balance = "0.00"
    @State private var interest = "0.00"
    @State private var currency = "GMD"
    @State private var transactions: [SavingsTransaction] = []
    @State private var direction = "To Savings"
    @State private var amount = ""
    @State private var reason = ""
    @State private var isLoading = false
    @State private var showTransferReview = false
    @State private var pin = ""
    @State private var isPinVisible = false
    @State private var isVerifyingPin = false
    @State private var transferError: String?
    @State private var alertMessage: String?

    private let directions = ["To Savings", "From Savings"]

    var body: some View {
        VStack(spacing: 0) {
            DiamaPayHeader(title: "Savings wallet", headerColor: SavingsStyle.blue)
            ScrollView {
                VStack(spacing: 20) {
                    balanceCard
                    transferCard
                    historyCard
                }
                .padding(16)
            }
            .background(SavingsStyle.background)
        }
        .navigationBarHidden(true)
        .onAppear(perform: loadSavings)
        .overlay {
            if showTransferReview {
                transferReviewPopup
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    .zIndex(10)
            }
        }
        .alert("Savings wallet", isPresented: Binding(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })) {
            Button("OK", role: .cancel) { alertMessage = nil }
        } message: { Text(alertMessage ?? "") }
    }

    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionTitle("Savings wallet balance")
            HStack {
                Text("Current Balance").foregroundColor(Color(hex: "58707B"))
                Spacer()
                Text("\(balance) \(currency)").fontWeight(.bold).foregroundColor(SavingsStyle.blue)
                Button(action: loadSavings) {
                    Image(systemName: "arrow.clockwise").font(.system(size: 22, weight: .semibold)).foregroundColor(SavingsStyle.cyan)
                }
                .disabled(isLoading)
            }
            .font(.system(size: 20))
            HStack {
                Text("Interest Acquired").foregroundColor(Color(hex: "58707B"))
                Spacer()
                Text("\(interest) \(currency)").fontWeight(.semibold).foregroundColor(Color(hex: "29323A"))
            }
            .font(.system(size: 17))
        }
        .padding(20)
        .savingsCard()
    }

    private var transferCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionTitle("Fund Transfer")
            HStack(spacing: 12) {
                ForEach(directions, id: \.self) { value in
                    Button { direction = value } label: {
                        HStack(spacing: 8) {
                            Image(systemName: direction == value ? "largecircle.fill.circle" : "circle")
                                .foregroundColor(direction == value ? SavingsStyle.cyan : .gray)
                            Text(value).foregroundColor(.gray)
                        }
                    }.buttonStyle(.plain)
                    if value == directions.first { Spacer(minLength: 0) }
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                fieldLabel("Amount")
                TextField("Enter Amount", text: $amount)
                    .keyboardType(.decimalPad)
                    .savingsInput()
            }
            VStack(alignment: .leading, spacing: 8) {
                fieldLabel("Reference")
                TextField("Transfer reason", text: $reason)
                    .textInputAutocapitalization(.sentences)
                    .savingsInput()
            }
            Button {
                pin = ""
                transferError = nil
                showTransferReview = true
            } label: {
                HStack { Spacer(); if isLoading { ProgressView().tint(.white) }; Text("Transfer").font(.system(size: 19, weight: .semibold)).tracking(1); Spacer() }
                    .foregroundColor(.white).frame(height: 56).background(SavingsStyle.blue, in: RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isLoading || Double(amount) == nil || (Double(amount) ?? 0) <= 0)
            .opacity((Double(amount) ?? 0) > 0 ? 1 : 0.62)
        }
        .padding(20)
        .savingsCard()
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionTitle("Transaction History")
            if transactions.isEmpty {
                Text(isLoading ? "Loading transactions…" : "No recent savings transactions")
                    .foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
            } else {
                ForEach(transactions) { transaction in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .top) {
                            Text(transaction.date).font(.system(size: 15, weight: .medium)).foregroundColor(SavingsStyle.ink)
                            Spacer()
                            Text("\(transaction.sign == "D" ? "−" : "+")\(transaction.amount) \(transaction.currency)")
                                .font(.system(size: 18, weight: .bold)).foregroundColor(SavingsStyle.blue)
                        }
                        Text(transaction.type).font(.system(size: 16, weight: .semibold)).foregroundColor(.gray)
                        Text("Ref: \(transaction.reference)").font(.system(size: 14)).foregroundColor(SavingsStyle.ink)
                    }
                    .padding(.vertical, 8)
                    if transaction.id != transactions.last?.id { Divider() }
                }
            }
        }
        .padding(20)
        .savingsCard()
    }

    private func sectionTitle(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 21, weight: .bold)).foregroundColor(SavingsStyle.blue)
            Rectangle().fill(SavingsStyle.cyan).frame(width: 110, height: 3)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title).font(.system(size: 15, weight: .medium)).foregroundColor(SavingsStyle.cyan)
    }

    private var transferReviewPopup: some View {
        ZStack {
            Color.black.opacity(0.60).ignoresSafeArea()
                .onTapGesture { closeTransferReview() }
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 14) {
                        Image(systemName: "lock.fill").font(.system(size: 25, weight: .medium))
                        Text("Fund Transfer").font(.system(size: 25, weight: .bold))
                    }
                    Text("Verify your transaction details")
                        .font(.system(size: 17, weight: .medium)).padding(.leading, 39)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(22)
                .background(SavingsStyle.cyan)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        reviewCard(title: "AMOUNT") {
                            Text("\(amount) \(currency)")
                                .font(.system(size: 29, weight: .bold)).foregroundColor(SavingsStyle.cyan)
                                .frame(maxWidth: .infinity).padding(.top, 8)
                        }
                        reviewCard(title: "RECIPIENT INFORMATION") {
                            HStack {
                                Text("Recipient").foregroundColor(SavingsStyle.ink)
                                Spacer()
                                Text(direction == "To Savings" ? "Savings wallet" : "Main wallet")
                                    .fontWeight(.semibold).foregroundColor(.gray)
                            }.font(.system(size: 16)).padding(.top, 6)
                            Divider().padding(.top, 4)
                        }
                        reviewCard(title: "DESCRIPTION") {
                            Text(reason.isEmpty ? "—" : reason).font(.system(size: 16)).foregroundColor(.gray).padding(.top, 3)
                        }
                        VStack(alignment: .leading, spacing: 10) {
                            Text("AUTHENTICATION").font(.system(size: 17, weight: .bold)).tracking(1).foregroundColor(SavingsStyle.ink)
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill").foregroundColor(SavingsStyle.cyan)
                                Group {
                                    if isPinVisible {
                                        TextField("PIN Code", text: $pin)
                                    } else {
                                        SecureField("PIN Code", text: $pin)
                                    }
                                }
                                .keyboardType(.numberPad)
                                .textContentType(.oneTimeCode)
                                Button { isPinVisible.toggle() } label: {
                                    Image(systemName: isPinVisible ? "eye" : "eye.slash").foregroundColor(.gray)
                                }
                            }
                            .font(.system(size: 17))
                            .padding(.horizontal, 14).frame(height: 58)
                            .background(RoundedRectangle(cornerRadius: 11).stroke(Color.gray.opacity(0.8), lineWidth: 1.3))
                            if let transferError {
                                Text(transferError).font(.system(size: 14)).foregroundColor(.red)
                            }
                        }
                        HStack(spacing: 12) {
                            Button(action: closeTransferReview) {
                                Text("Cancel").frame(maxWidth: .infinity).frame(height: 54)
                                    .foregroundColor(SavingsStyle.cyan).background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.25), lineWidth: 1))
                            }
                            Button(action: verifyPinAndTransfer) {
                                HStack(spacing: 8) {
                                    if isVerifyingPin { ProgressView().tint(.white) }
                                    Text("Transfer")
                                }
                                .frame(maxWidth: .infinity).frame(height: 54).foregroundColor(.white)
                                .background(SavingsStyle.cyan, in: RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(isVerifyingPin || pin.isEmpty)
                            .opacity(pin.isEmpty ? 0.6 : 1)
                        }
                        .font(.system(size: 18, weight: .semibold))
                    }
                    .padding(18)
                }
                .background(Color.white)
            }
            .frame(maxWidth: 560, maxHeight: 720)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(color: .black.opacity(0.24), radius: 18, x: 0, y: 8)
            .padding(.horizontal, 24)
        }
    }

    private func reviewCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 17, weight: .bold)).tracking(1).foregroundColor(SavingsStyle.ink)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "F8F9FB"), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "E1E5EA"), lineWidth: 1.2))
    }

    private func closeTransferReview() {
        showTransferReview = false
        pin = ""
        transferError = nil
    }

    private func verifyPinAndTransfer() {
        guard !pin.isEmpty else {
            transferError = "Enter your PIN to continue."
            return
        }
        isVerifyingPin = true
        transferError = nil
        let data = UserDataManager.shared
        var request = RequestCheckPin()
        request.walletNumber = data.getWalletNumber()
        request.phoneNumber = data.getPhoneNumber()
        request.pin = pin
        request.source = "W"
        request.entityId = data.getUserCode()
        request.bank = data.getBankCode().isEmpty ? "00100" : data.getBankCode()
        request.requestId = savingsRequestID()
        request.requestDate = savingsRequestDate()

        APIClient.shared.checkPin(request: request) { result in
            DispatchQueue.main.async {
                isVerifyingPin = false
                switch result {
                case .success(let response) where response.respCode == "000":
                    isVerifyingPin = true
                    submitTransfer()
                case .success(let response):
                    transferError = response.message ?? "PIN verification failed. Please try again."
                    pin = ""
                case .failure(let error):
                    transferError = (error as? APIError)?.message ?? error.localizedDescription
                }
            }
        }
    }

    private func loadSavings() {
        guard !isLoading else { return }
        isLoading = true
        let data = UserDataManager.shared
        APIClient.shared.getSavingsBalance(request: RequestSavingBalance(
            walletNumber: data.getWalletNumber(), phoneNumber: data.getPhoneNumber(), bank: data.getBankCode(), requestId: savingsRequestID(), requestDate: savingsRequestDate(), entityId: data.getUserCode()
        )) { result in
            DispatchQueue.main.async {
                if case .success(let response) = result, response.isSuccessful, let values = response.result {
                    balance = String(format: "%.2f", Double(values["availableBalance"] as? String ?? "0") ?? 0)
                    interest = String(format: "%.2f", Double(values["interest"] as? String ?? "0") ?? 0)
                    currency = values["currencyWording"] as? String ?? "GMD"
                } else if case .failure(let error) = result { alertMessage = error.localizedDescription }
                loadTransactions()
            }
        }
    }

    private func loadTransactions() {
        let request = savingsStatementRequest(from: Date().addingTimeInterval(-30 * 24 * 60 * 60), to: Date(), format: "P")
        APIClient.shared.getSavingsLast5(request: request) { result in
            DispatchQueue.main.async {
                if case .success(let response) = result, response.isSuccessful {
                    transactions = (response.result ?? []).compactMap { item in
                        guard let row = item as? [String: Any] else { return nil }
                        return SavingsTransaction(
                            date: row["authDate"] as? String ?? "",
                            reference: row["trxRef"] as? String ?? "—",
                            amount: row["amount"] as? String ?? "0.00",
                            currency: row["currency"] as? String ?? currency,
                            sign: row["sign"] as? String ?? "C",
                            type: row["type"] as? String ?? "Transaction"
                        )
                    }
                }
                isLoading = false
            }
        }
    }

    private func submitTransfer() {
        let data = UserDataManager.shared
        let common = (amount: amount.trimmingCharacters(in: .whitespaces), reason: reason.trimmingCharacters(in: .whitespaces))
        isLoading = true
        let completion: (Result<ResponseService, Error>) -> Void = { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let response):
                    if response.isSuccessful {
                        isVerifyingPin = false
                        closeTransferReview()
                        alertMessage = response.message ?? "Transfer completed successfully."
                        amount = ""
                        reason = ""
                        loadSavings()
                    } else {
                        isVerifyingPin = false
                        transferError = response.message ?? "Transfer could not be completed. Please try again."
                    }
                case .failure(let error):
                    isVerifyingPin = false
                    transferError = error.localizedDescription
                }
            }
        }
        if direction == "To Savings" {
            APIClient.shared.creditSavingsWallet(request: RequestCreditSaving(walletNumber: data.getWalletNumber(), phoneNumber: data.getPhoneNumber(), bank: data.getBankCode(), amount: common.amount, reason: common.reason, requestId: savingsRequestID(), requestDate: savingsRequestDate(), entityId: data.getUserCode()), completion: completion)
        } else {
            APIClient.shared.debitSavingsWallet(request: RequestDebitSaving(walletNumber: data.getWalletNumber(), phoneNumber: data.getPhoneNumber(), bank: data.getBankCode(), amount: common.amount, reason: common.reason, requestId: savingsRequestID(), requestDate: savingsRequestDate(), entityId: data.getUserCode()), completion: completion)
        }
    }
}

struct SavingsWalletStatementView: View {
    @State private var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var format = "PDF (Portable Document)"
    @State private var isLoading = false
    @State private var alertMessage: String?
    private let formats = ["PDF (Portable Document)", "Excel (Spreadsheet)", "CSV (Comma Separated Values)"]

    var body: some View {
        VStack(spacing: 0) {
            DiamaPayHeader(title: "Savings Wallet Statement", headerColor: SavingsStyle.blue)
            ScrollView {
                VStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 20) {
                        statementTitle("Statement Options")
                        Text("Select Period").font(.system(size: 17)).foregroundColor(.gray)
                        HStack(spacing: 12) {
                            dateField("Start Date", date: $startDate)
                            dateField("End Date", date: $endDate)
                        }
                        Text("Select Format").font(.system(size: 17)).foregroundColor(.gray).padding(.top, 2)
                        ForEach(formats, id: \.self) { value in
                            Button { format = value } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: format == value ? "largecircle.fill.circle" : "circle")
                                        .foregroundColor(format == value ? SavingsStyle.cyan : .gray)
                                    Text(value).foregroundColor(.gray).multilineTextAlignment(.leading)
                                }.font(.system(size: 16))
                            }.buttonStyle(.plain)
                        }
                        Button(action: generateStatement) {
                            HStack { Spacer(); if isLoading { ProgressView().tint(.white) }; Text("Generate Statement").font(.system(size: 18, weight: .semibold)).tracking(1); Spacer() }
                                .foregroundColor(.white).frame(height: 56).background(SavingsStyle.blue, in: RoundedRectangle(cornerRadius: 12))
                        }.disabled(isLoading || startDate > endDate)
                    }.padding(20).savingsCard()

                    VStack(alignment: .leading, spacing: 18) {
                        statementTitle("Information")
                        Text("The savings account statement will be generated and sent to the email address associated with your account. Please check your inbox after clicking the ‘Generate Statement’ button.")
                            .font(.system(size: 16)).foregroundColor(SavingsStyle.ink)
                    }.padding(20).savingsCard()
                }
                .padding(16)
            }.background(SavingsStyle.background)
        }
        .navigationBarHidden(true)
        .alert("Savings statement", isPresented: Binding(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })) {
            Button("OK", role: .cancel) { alertMessage = nil }
        } message: { Text(alertMessage ?? "") }
    }

    private func dateField(_ title: String, date: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.system(size: 15, weight: .medium)).foregroundColor(SavingsStyle.cyan)
            DatePicker(title, selection: date, in: ...Date(), displayedComponents: .date)
                .labelsHidden().datePickerStyle(.compact).padding(.horizontal, 8).frame(maxWidth: .infinity, minHeight: 48)
                .background(RoundedRectangle(cornerRadius: 10).stroke(SavingsStyle.ink, lineWidth: 1.3))
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statementTitle(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 21, weight: .medium)).foregroundColor(SavingsStyle.blue)
            Rectangle().fill(SavingsStyle.cyan).frame(width: 110, height: 3)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private func generateStatement() {
        isLoading = true
        let type = format.hasPrefix("PDF") ? "P" : (format.hasPrefix("Excel") ? "E" : "C")
        APIClient.shared.requestSavingsEStatement(request: savingsStatementRequest(from: startDate, to: endDate, format: type)) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let response): alertMessage = response.message ?? (response.isSuccessful ? "Your statement has been requested. Check your email." : "Unable to generate the statement.")
                case .failure(let error): alertMessage = error.localizedDescription
                }
            }
        }
    }
}

private extension View {
    func savingsCard() -> some View {
        background(Color.white, in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.black.opacity(0.04), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.13), radius: 7, x: 0, y: 4)
    }

    func savingsInput() -> some View {
        padding(.horizontal, 14).frame(height: 56)
            .background(RoundedRectangle(cornerRadius: 11).stroke(SavingsStyle.ink, lineWidth: 1.4))
    }
}

private func savingsRequestID() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyMMdd"
    return formatter.string(from: Date()) + String(format: "%06d", Int.random(in: 0..<1_000_000))
}

private func savingsRequestDate() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return formatter.string(from: Date())
}

private func savingsStatementRequest(from: Date, to: Date, format: String) -> RequestEStatement {
    let data = UserDataManager.shared
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    return RequestEStatement(walletNumber: data.getWalletNumber(), phoneNumber: data.getPhoneNumber(), source: "W", bank: data.getBankCode(), campaignId: "", groupId: "", dateFrom: dateFormatter.string(from: from), dateTo: dateFormatter.string(from: to), type: format, pin: data.getPinForAPI(), requestId: savingsRequestID(), requestDate: savingsRequestDate(), entityId: data.getUserCode())
}
