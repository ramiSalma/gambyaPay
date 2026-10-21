import SwiftUI

struct SideMenuView: View {
    var onSelect: (String) -> Void

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                header

                sectionHeader("PROFILE")
                item("person.crop.circle", "My Profile", "profile")
                item("person.2", "My Beneficiaries", "beneficiaries")
                sectionDivider

                sectionHeader("LOANS")
                item("wallet.bifold", "Request a Loan", "loanRequest")
                item("clock.arrow.circlepath", "My Loan Requests", "loanRequests")
                item("questionmark.bubble", "FAQs / Terms and Conditions", "loanHelp")
                sectionDivider

                sectionHeader("TRANSFERS")
                item("arrow.left.arrow.right", "Transfer to Wallet", "walletTransfer")
                item("wallet.bifold.fill", "Wallet to Account", "walletToAccountTransfer")
                item("bankToWallet", "Account to Wallet", "accountToWalletTransfer")
                item("voucher", "Money Voucher", "moneyVoucher")
                item("iphone", "Mobile Money", "mobileMoney")
                item("qrcode", "QR Transfer", "qr")
                item("wallet.pass", "Crowd Funding", "sponsor")
                item("repeat", "Standing Instructions", "si")
                sectionDivider

                sectionHeader("FOOD SERVICES")
                item("fork.knife", "Order food", "orderFood")
                item("clock.arrow.circlepath", "Food history", "orderHistory")
                item("exclamationmark.triangle", "Complaints", "foodComplaints")
                sectionDivider

                sectionHeader("RECHARGES")
                item("phone", "Phone Credit", "phoneCredit")
                item("antenna.radiowaves.left.and.right", "Buy Data", "buyData")
                item("creditcard", "Bill Payment", "billPayment")
                sectionDivider

                sectionHeader("SPONSOR")
                item("person.2", "Sponsored Wallets", "sponsored")
                item("person.3", "Sponsoring Wallets", "sponsoring")
                sectionDivider

                sectionHeader("SAVINGS")
                item("banknote", "Savings wallet", "savings")
                item("waveform.path", "Savings Wallet Statement", "savingsStatement")
                sectionDivider

                sectionHeader("TRANSACTIONS")
                item("list.bullet.rectangle", "Transaction History", "transactions")
                sectionDivider

                sectionHeader("WALLET MANAGEMENT")
                item("gauge.with.needle", "Limits", "limits")
                item("deactivate", "Deactivate Wallet", "deactivate")
                item("pending", "Pending Transactions", "pending")
                sectionDivider

                sectionHeader("HELP")
                item("gearshape", "Settings", "settings")
                item("bubble.left", "Send Feedback", "comment")
                item("exclamationmark.bubble", "File a Complaint", "complaint")
                DrawerItem(icon: "phone", title: "Contact Us") {
                    makePhoneCall(phoneNumber: "+224612008699")
                }
                item("terms", "Terms and Conditions", "terms")
                item("faq", "FAQ", "FAQ")
                item("rectangle.portrait.and.arrow.right", "Logout", "logout")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
        }
        .background(Color.white)
        .ignoresSafeArea(edges: .top)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("EWALLET")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Text("Your Secure Digital Wallet")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.96))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 22)
        .padding(.top, 70)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, alignment: .bottomLeading)
        .background(Color(hex: "174EA6").ignoresSafeArea(edges: .top))
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .medium))
            .tracking(1.5)
            .foregroundColor(Color(hex: "174EA6"))
            .padding(.horizontal, 22)
            .padding(.top, 20)
            .padding(.bottom, 10)
    }

    private func item(_ icon: String, _ title: String, _ selection: String) -> some View {
        DrawerItem(icon: icon, title: title) {
            onSelect(selection)
        }
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(Color(hex: "E1E4E8"))
            .frame(height: 1)
            .padding(.top, 8)
    }

    private func makePhoneCall(phoneNumber: String) {
        let cleanedNumber = phoneNumber.replacingOccurrences(of: " ", with: "")
        guard let url = URL(string: "tel://\(cleanedNumber)"),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url, options: [:])
    }
}

struct SideMenuView_Previews: PreviewProvider {
    static var previews: some View {
        SideMenuView { _ in }
            .frame(width: 300)
            .previewLayout(.sizeThatFits)
    }
}
