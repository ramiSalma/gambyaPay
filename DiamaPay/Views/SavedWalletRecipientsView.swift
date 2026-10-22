import SwiftUI

struct SavedWalletRecipientsView: View {
    @ObservedObject private var localization = AppLanguageStore.shared
    @Environment(\.dismiss) private var dismiss
    var includeMobileMoneyRecipients = false
    let onSelect: (WalletBeneficiary) -> Void
    @State private var recipients: [WalletBeneficiary] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var search = ""

    private var filtered: [WalletBeneficiary] {
        guard !search.isEmpty else { return recipients }
        return recipients.filter {
            ($0.name ?? "").localizedCaseInsensitiveContains(search) || ($0.destination ?? "").contains(search)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView(AppStrings.loadingSavedRecipients)
                } else if let errorMessage {
                    VStack(spacing: 16) {
                        Text(AppStrings.option(errorMessage)).multilineTextAlignment(.center)
                        Button(AppStrings.tryAgain, action: loadRecipients)
                    }.padding()
                } else if recipients.isEmpty {
                    Text(AppStrings.noSavedWalletRecipients).foregroundColor(.secondary)
                } else {
                    List {
                        if filtered.isEmpty {
                            Text(AppStrings.noMatchingRecipients).foregroundColor(.secondary)
                        }
                        ForEach(Array(filtered.enumerated()), id: \.offset) { _, recipient in
                            Button {
                                onSelect(recipient)
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(recipient.name?.isEmpty == false ? recipient.name! : AppStrings.savedRecipient)
                                        .foregroundColor(.primary)
                                    Text(recipient.destination ?? "")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .searchable(text: $search, prompt: AppStrings.nameOrRecipientNumber)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(AppStrings.savedRecipients2)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(AppStrings.close) { dismiss() } }
            }
            .onAppear(perform: loadRecipients)
        }
    }

    private func loadRecipients() {
        guard !isLoading else { return }
        let user = UserDataManager.shared
        guard !user.getPhoneNumber().isEmpty else {
            errorMessage = AppStrings.pleaseSignInAgainToLoadSavedRecipients
            return
        }
        isLoading = true
        errorMessage = nil
        let request = WalletBeneficiaryListRequest(
            phoneNumber: user.getPhoneNumber(),
            requestId: DateFormatter.with(format: "yyMMdd").string(from: Date()) + String(format: "%06d", Int.random(in: 0...999999)),
            requestDate: DateFormatter.with(format: "yyyy-MM-dd HH:mm:ss").string(from: Date()),
            entityId: user.getUserCode().isEmpty ? user.getPhoneNumber() : user.getUserCode()
        )
        APIClient.shared.listWalletBeneficiaries(request: request) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let response):
                    guard response.respCode == "000" else {
                        errorMessage = response.message ?? AppStrings.unableToLoadSavedRecipients
                        return
                    }
                    recipients = (response.result ?? []).filter { $0.isWalletRecipient || (includeMobileMoneyRecipients && $0.isMobileMoneyRecipient) }
                case .failure(let error):
                    errorMessage = (error as? APIError)?.message ?? AppStrings.unableToLoadSavedRecipientsPleaseTryAgain
                }
            }
        }
    }
}
