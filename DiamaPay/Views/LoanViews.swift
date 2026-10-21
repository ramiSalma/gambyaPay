import SwiftUI

private let loanBlue = Color(hex: "174EA6")

struct LoanRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var providers: [Provider] = []
    @State private var purposes: [LoanOption] = []
    @State private var provider: Provider?
    @State private var purpose: LoanOption?
    @State private var amount = ""
    @State private var duration = 12
    @State private var remarks = ""
    @State private var acceptedTerms = false
    @State private var isLoading = false
    @State private var alertMessage: String?
    @State private var submitted = false

    private let durations = [3, 6, 9, 12, 18, 24, 36]

    var body: some View {
        VStack(spacing: 0) {
            loanNavigationBar(title: "Request a Loan", onBack: { dismiss() })
            ScrollView {
                VStack(spacing: 14) {
                    formCard("Loan Provider") {
                        Picker("Select Loan Provider", selection: $provider) {
                            Text("Select Loan Provider").tag(Provider?.none)
                            ForEach(providers, id: \.id) { item in Text(item.displayName).tag(Optional(item)) }
                        }
                        .pickerStyle(.menu)
                    }
                    formCard("Loan Amount") {
                        TextField("Enter amount (GMD)", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                    formCard("Purpose of Loan") {
                        Picker("Select Purpose", selection: $purpose) {
                            Text("Select Purpose").tag(LoanOption?.none)
                            ForEach(purposes) { item in Text(item.name).tag(Optional(item)) }
                        }
                        .pickerStyle(.menu)
                    }
                    formCard("Repayment Period") {
                        Picker("Select repayment period", selection: $duration) {
                            ForEach(durations, id: \.self) { Text("\($0) months").tag($0) }
                        }
                        .pickerStyle(.menu)
                    }
                    formCard("Remarks (optional)") {
                        TextField("Add a note", text: $remarks, axis: .vertical)
                            .lineLimit(2...4)
                    }
                    Toggle(isOn: $acceptedTerms) {
                        Text("I accept the **Loan Terms & Conditions**")
                            .font(.system(size: 15))
                    }
                    .tint(loanBlue)
                    .padding(.horizontal, 4)
                    Button(action: submit) {
                        HStack { if isLoading { ProgressView().tint(.white) }; Text("SUBMIT REQUEST").fontWeight(.bold) }
                            .frame(maxWidth: .infinity).padding(.vertical, 17)
                    }
                    .buttonStyle(LoanPrimaryButtonStyle())
                    .disabled(isLoading)
                }
                .padding(18)
            }
            .background(Color(hex: "F5F6F8"))
        }
        .navigationBarHidden(true)
        .task { loadOptions() }
        .alert(submitted ? "Request submitted" : "Loan request", isPresented: Binding(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })) {
            Button("OK", role: .cancel) { if submitted { dismiss() } }
        } message: { Text(alertMessage ?? "") }
    }

    private func loadOptions() {
        APIClient.shared.getLoanProviders { result in
            if case .success(let values) = result { providers = values }
        }
        APIClient.shared.getLoanPurposes { result in
            if case .success(let values) = result { purposes = values }
        }
    }

    private func submit() {
        guard let provider, let providerId = provider.id.flatMap(Int64.init), let purpose else { alertMessage = "Choose a loan provider and purpose."; return }
        guard let amountValue = Double(amount), amountValue > 0 else { alertMessage = "Enter a valid loan amount."; return }
        guard acceptedTerms else { alertMessage = "Please accept the loan terms to continue."; return }
        let user = UserDataManager.shared
        let request = LoanRequestPayload(phoneNumber: user.getPhoneNumber(), entityId: user.getUserCode().isEmpty ? user.getPhoneNumber() : user.getUserCode(), providerId: providerId, purposeId: purpose.id, amount: amountValue, duration: duration, remarks: remarks)
        isLoading = true
        APIClient.shared.createLoan(request: request) { result in
            isLoading = false
            switch result {
            case .success(let response):
                submitted = true
                alertMessage = response.message ?? "Your loan request has been received."
            case .failure(let error): alertMessage = error.localizedDescription
            }
        }
    }
}

struct LoanRequestsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var loans: [LoanRecord] = []
    @State private var selectedStatus = "PENDING"
    @State private var selectedProvider = "All"
    @State private var appliedStatus = "PENDING"
    @State private var appliedProvider = "All"
    @State private var alertMessage: String?
    @State private var isLoading = false
    @State private var selectedLoan: LoanRecord?
    private let statuses = ["All", "PENDING", "UNDER_REVIEW", "APPROVED", "REJECTED", "CANCELLED", "FAILED", "EXPIRED"]
    private var providers: [String] { ["All"] + Array(Set(loans.compactMap { $0.provider?.name })).sorted() }
    private var filteredLoans: [LoanRecord] {
        loans.filter { (appliedStatus == "All" || ($0.status ?? "").uppercased() == appliedStatus) && (appliedProvider == "All" || $0.provider?.name == appliedProvider) }
    }

    var body: some View {
        VStack(spacing: 0) {
            loanNavigationBar(title: "My Loan Requests", onBack: { dismiss() })
            ScrollView {
                VStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Filter Loan Requests").font(.system(size: 21, weight: .bold)).foregroundColor(loanBlue)
                        Text("Filter by status or provider").font(.subheadline).foregroundColor(.secondary)
                        HStack {
                            outlinedLoanFilter(title: "Status", selection: $selectedStatus, options: statuses.map { ($0, $0.replacingOccurrences(of: "_", with: " ")) })
                            outlinedLoanFilter(title: "Provider", selection: $selectedProvider, options: providers.map { ($0, $0) }, highlighted: true)
                        }
                        .frame(height: 68)
                        HStack {
                            Button("Reset") {
                                selectedStatus = "All"
                                selectedProvider = "All"
                                appliedStatus = "All"
                                appliedProvider = "All"
                            }
                            .buttonStyle(LoanFilterResetButtonStyle())
                            Button("Filter") {
                                appliedStatus = selectedStatus
                                appliedProvider = selectedProvider
                            }
                            .buttonStyle(LoanFilterApplyButtonStyle())
                        }
                        .padding(.top, 4)
                    }
                    .padding(18).background(.white).clipShape(RoundedRectangle(cornerRadius: 22)).shadow(color: .black.opacity(0.08), radius: 8, y: 3)

                    if isLoading { ProgressView().padding(30) }
                    else if filteredLoans.isEmpty { ContentUnavailableView("No loan requests", systemImage: "doc.text.magnifyingglass", description: Text("Your submitted loan requests will appear here.")) }
                    else {
                        ForEach(filteredLoans) { loan in
                            Button { selectedLoan = loan } label: { loanRow(loan) }
                                .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(hex: "F5F6F8"))
        }
        .navigationBarHidden(true)
        .task { loadLoans() }
        .sheet(item: $selectedLoan) { loan in LoanDetailSheet(loan: loan) }
        .alert("Loan requests", isPresented: Binding(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })) { Button("OK", role: .cancel) {} } message: { Text(alertMessage ?? "") }
    }

    private func loadLoans() {
        isLoading = true
        APIClient.shared.getLoans(phoneNumber: UserDataManager.shared.getPhoneNumber()) { result in
            isLoading = false
            switch result {
            case .success(let response): loans = response.result ?? []
            case .failure(let error): alertMessage = error.localizedDescription
            }
        }
    }

    private func loanRow(_ loan: LoanRecord) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "doc.text.fill").font(.title3).foregroundColor(loanBlue.opacity(0.7))
            VStack(alignment: .leading, spacing: 5) {
                Text(loan.provider?.name ?? "Loan provider").font(.system(size: 17, weight: .bold)).foregroundColor(.primary)
                Text(loanAmount(loan.amount)).font(.system(size: 16, weight: .semibold)).foregroundColor(loanBlue)
                Text(loan.requestDate ?? "Date unavailable").font(.caption).foregroundColor(.secondary).lineLimit(1)
            }
            Spacer(minLength: 4)
            Text((loan.status ?? "PENDING").replacingOccurrences(of: "_", with: " "))
                .font(.system(size: 12, weight: .bold)).multilineTextAlignment(.trailing).foregroundColor(statusColor(loan.status))
            Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundColor(.gray)
        }
        .padding(16).background(.white).clipShape(RoundedRectangle(cornerRadius: 20)).shadow(color: .black.opacity(0.08), radius: 6, y: 3)
    }
}

private func outlinedLoanFilter(title: String, selection: Binding<String>, options: [(String, String)], highlighted: Bool = false) -> some View {
    Menu {
        ForEach(Array(options.enumerated()), id: \.offset) { _, option in
            Button(option.1) { selection.wrappedValue = option.0 }
        }
    } label: {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(highlighted ? loanBlue : Color(hex: "737373"))
                .padding(.horizontal, 7)
                .background(.white)
                .offset(x: 12, y: 8)
                .zIndex(1)
            HStack(spacing: 6) {
                Text(options.first(where: { $0.0 == selection.wrappedValue })?.1 ?? selection.wrappedValue)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
                Image(systemName: "chevron.down").font(.system(size: 13, weight: .semibold)).foregroundColor(Color(hex: "707070"))
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 51, maxHeight: 51)
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(highlighted ? loanBlue : Color(hex: "A0A0A0"), lineWidth: highlighted ? 2 : 1.2))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
    .frame(maxWidth: .infinity)
}

private struct LoanDetailSheet: View {
    let loan: LoanRecord
    @State private var latestLoan: LoanRecord?
    @Environment(\.dismiss) private var dismiss
    @State private var message: String?
    @State private var confirmingCancel = false
    private var record: LoanRecord { latestLoan ?? loan }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Loan Request Details").font(.system(size: 25, weight: .bold)).foregroundColor(loanBlue).padding(.bottom, 18)
                    detail("Reference", "\(record.id)")
                    detail("Loan Provider", record.provider?.name ?? "—")
                    detail("Requested Amount", loanAmount(record.amount), emphasized: true)
                    detail("Purpose", record.purpose?.name ?? "—")
                    detail("Repayment Period", record.duration.map { "\($0) Months" } ?? "—")
                    detail("Request Date", record.requestDate ?? "—")
                    detail("Approval Date", record.approvedDate ?? "—")
                    detail("Remarks", record.remarks?.isEmpty == false ? record.remarks! : "—")
                    detail("Current Status", (record.status ?? "PENDING").replacingOccurrences(of: "_", with: " "), emphasized: true, tint: statusColor(record.status))
                    Text("Your request status will update as it progresses.").font(.subheadline).foregroundColor(.secondary).padding(.top, 20)
                    if (record.status ?? "").uppercased() == "PENDING" || (record.status ?? "").uppercased() == "UNDER_REVIEW" {
                        Button("Cancel request", role: .destructive) { confirmingCancel = true }.padding(.top, 20)
                    }
                }.padding(20)
            }
            .navigationTitle("Loan Details")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                APIClient.shared.getLoan(id: loan.id) { result in
                    if case .success(let response) = result { latestLoan = response.result }
                }
            }
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
            .confirmationDialog("Cancel this loan request?", isPresented: $confirmingCancel, titleVisibility: .visible) {
                Button("Cancel request", role: .destructive) { cancel() }
            }
            .alert("Loan request", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) { Button("OK", role: .cancel) { dismiss() } } message: { Text(message ?? "") }
        }
    }
    private func detail(_ title: String, _ value: String, emphasized: Bool = false, tint: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(.secondary)
            Text(value).font(.system(size: emphasized ? 20 : 16, weight: emphasized ? .bold : .regular)).foregroundColor(tint)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 13).overlay(alignment: .bottom) { Rectangle().fill(Color.gray.opacity(0.22)).frame(height: 1) }
    }
    private func cancel() {
        APIClient.shared.cancelLoan(id: loan.id) { result in
            switch result { case .success: message = "Your request has been cancelled."; case .failure(let error): message = error.localizedDescription }
        }
    }
}

struct LoanHelpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    @State private var expanded: String?
    @State private var accepted = false
    private let terms: [(String, String)] = [
        ("Eligibility", "You must have an active GambiaPay wallet and provide accurate information. Each lender may apply additional eligibility checks before approving a request."),
        ("Loan Conditions", "Loan amounts, fees, interest, and final approval are determined by the selected loan provider. Review the provider's offer carefully before accepting it."),
        ("Repayment", "Repayment dates and methods are set by the loan provider. Keep sufficient funds available and contact the provider if you need help."),
        ("Privacy Policy", "Information entered for a loan request is shared with the selected provider to assess and process your application."),
    ]
    private let faqs: [(String, String)] = [
        ("How do I apply for a loan?", "Choose a provider, enter the amount and purpose, select a repayment period, review the terms, then submit your request."),
        ("How long does approval take?", "The selected provider reviews each application. Processing times vary; check My Loan Requests for status updates."),
        ("Can I cancel my loan request?", "You can cancel a request while its status is pending or under review from the request details screen."),
        ("How do I repay my loan?", "Repayment is handled by the loan provider. Follow the repayment instructions and schedule they provide."),
        ("What happens if I miss a payment?", "Contact your loan provider promptly. Fees or other consequences depend on the provider's agreement."),
        ("Can I repay my loan early?", "Early repayment rules depend on your provider. Contact them to confirm any conditions or fees."),
    ]
    private var visibleTerms: [(String, String)] { terms.filter { search.isEmpty || $0.0.localizedCaseInsensitiveContains(search) || $0.1.localizedCaseInsensitiveContains(search) } }
    private var visibleFaqs: [(String, String)] { faqs.filter { search.isEmpty || $0.0.localizedCaseInsensitiveContains(search) || $0.1.localizedCaseInsensitiveContains(search) } }
    var body: some View {
        VStack(spacing: 0) {
            loanNavigationBar(title: "Loan Help", onBack: { dismiss() })
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Loan Terms & Conditions").font(.system(size: 25, weight: .bold))
                    Text("GambiaPay · Loan services").font(.system(size: 16, weight: .semibold)).foregroundColor(loanBlue)
                    HStack(spacing: 10) { Image(systemName: "magnifyingglass").foregroundColor(.secondary); TextField("Search terms and FAQs", text: $search) }
                        .padding(15).background(.white).clipShape(RoundedRectangle(cornerRadius: 18)).shadow(color: .black.opacity(0.06), radius: 5, y: 2)
                    ForEach(visibleTerms, id: \.0) { row in expandableRow(row.0, detail: row.1) }
                    Button { accepted = true } label: { Text(accepted ? "Accepted" : "Accept & Continue").fontWeight(.bold).frame(maxWidth: .infinity).padding(.vertical, 15) }
                        .buttonStyle(LoanPrimaryButtonStyle())
                    Text("Loan FAQs").font(.system(size: 25, weight: .bold)).padding(.top, 14)
                    ForEach(visibleFaqs, id: \.0) { row in expandableRow(row.0, detail: row.1) }
                }.padding(18)
            }.background(Color(hex: "F5F6F8"))
        }
        .navigationBarHidden(true)
    }
    private func expandableRow(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { withAnimation(.easeInOut(duration: 0.2)) { expanded = expanded == title ? nil : title } } label: {
                HStack { Text(title).font(.system(size: 16, weight: .semibold)).foregroundColor(.primary).multilineTextAlignment(.leading); Spacer(); Image(systemName: expanded == title ? "chevron.down" : "chevron.right").foregroundColor(.gray) }.padding(17)
            }
            if expanded == title { Text(detail).font(.subheadline).foregroundColor(.secondary).padding([.horizontal, .bottom], 17) }
        }.background(.white).clipShape(RoundedRectangle(cornerRadius: 18)).shadow(color: .black.opacity(0.06), radius: 5, y: 2)
    }
}

private func loanNavigationBar(title: String, onBack: @escaping () -> Void) -> some View {
    HStack {
        Button(action: onBack) { Image(systemName: "chevron.left").font(.system(size: 18, weight: .semibold)).foregroundColor(.white).frame(width: 44, height: 44) }
        Spacer()
        Text(title).font(.system(size: 20, weight: .semibold)).foregroundColor(.white)
        Spacer()
        Color.clear.frame(width: 44, height: 44)
    }
    .padding(.horizontal, 8).frame(height: 54).background(loanBlue)
}

private func formCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 12) {
        Text(title).font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
        content().font(.system(size: 16)).tint(loanBlue).padding(13).frame(maxWidth: .infinity, alignment: .leading).background(Color(hex: "F8F9FB")).clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .padding(16).background(.white).clipShape(RoundedRectangle(cornerRadius: 18)).shadow(color: .black.opacity(0.06), radius: 5, y: 2)
}

private struct LoanPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.foregroundColor(.white).background(loanBlue.opacity(configuration.isPressed ? 0.8 : 1)).clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct LoanSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.fontWeight(.semibold).foregroundColor(loanBlue).frame(maxWidth: .infinity).padding(.vertical, 13).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 10)).overlay(RoundedRectangle(cornerRadius: 10).stroke(loanBlue.opacity(0.25)))
    }
}

private struct LoanFilterResetButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .medium))
            .tracking(1)
            .foregroundColor(loanBlue)
            .frame(maxWidth: .infinity)
            .frame(height: 47)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "E0E0E0"), lineWidth: 1))
    }
}

private struct LoanFilterApplyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .tracking(1)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 47)
            .background(loanBlue.opacity(configuration.isPressed ? 0.82 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .shadow(color: .black.opacity(0.14), radius: 3, y: 2)
    }
}

private func statusColor(_ status: String?) -> Color {
    switch (status ?? "PENDING").uppercased() {
    case "APPROVED": return Color(hex: "37A45A")
    case "REJECTED", "CANCELLED", "FAILED": return Color(hex: "9C27B0")
    case "EXPIRED": return Color(hex: "777777")
    default: return Color(hex: "E5A900")
    }
}

private func loanAmount(_ amount: Double?) -> String {
    String(format: "GMD %.2f", amount ?? 0)
}
