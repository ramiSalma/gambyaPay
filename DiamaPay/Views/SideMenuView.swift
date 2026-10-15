import SwiftUI


struct SideMenuView: View {
    var onSelect: (String) -> Void
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("EWALLET")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    Text("Your Secure Digital Wallet")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.95))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.top, 76)
                .padding(.bottom, 30)
                .background(Color(hex: "174EA6").ignoresSafeArea(edges: .top))
                
                Text("TRANSFERS")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.5)
                    .foregroundColor(Color(hex: "174EA6"))
                    .padding(.horizontal, 28)
                    .padding(.top, 28)
                    .padding(.bottom, 14)
                
                DrawerItem(icon: "arrow.left.arrow.right", title: "Transfer to Wallet") {
                    onSelect("walletTransfer")
                }
                DrawerItem(icon: "wallet.bifold.fill", title: "Wallet to Account") {
                    onSelect("walletToAccountTransfer")
                }
             
                DrawerItem(icon: "bankToWallet", title: "Account to Wallet") {
                    onSelect("accountToWalletTransfer")
                }
                DrawerItem(icon: "voucher", title: "Money Voucher") {
                    onSelect("moneyVoucher")
                }
                DrawerItem(icon: "qrcode", title: "QR Transfer") {
                    onSelect("qr")
                }
                DrawerItem(icon: "arrow.left.arrow.right", title: "Standing Instructions") {
                    onSelect("si")
                }
                
                sectionDivider
                
                Text("BILL PAYMENTS")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.5)
                    .foregroundColor(Color(hex: "174EA6"))
                    .padding(.horizontal, 28)
                    .padding(.top, 24)
                    .padding(.bottom, 14)
                
                DrawerItem(icon: "bill", title: "Pay Bills") {
                    onSelect("billPayment")
                }
                
                sectionDivider
                // Support group
                Text("SPONSORSHIPS")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.5)
                    .foregroundColor(Color(hex: "174EA6"))
                    .padding(.horizontal, 28)
                    .padding(.top, 24)
                    .padding(.bottom, 14)
                
                DrawerItem(icon: "sponsored", title: "Sponsored Wallets") {
                    onSelect("sponsored")
                }
                DrawerItem(icon: "sponsor", title: "My Sponsors") {
                    onSelect("sponsoring")
                }
               
                
                sectionDivider
                Text("WALLET MANAGEMENT")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.5)
                    .foregroundColor(Color(hex: "174EA6"))
                    .padding(.horizontal, 28)
                    .padding(.top, 24)
                    .padding(.bottom, 14)
                
                DrawerItem(icon: "gauge.with.needle.fill", title: "My Limits") {
                    onSelect("limits")
                }
                
                DrawerItem(icon: "savingsstatement", title: "Mini Statement") {
                    onSelect("statement")
                }
                
                DrawerItem(icon: "deactivate", title: "Deactivate Account") {
                    onSelect("deactivate")
                }
                
              
                DrawerItem(icon: "pending", title: "Pending Transactions") {
                    onSelect("pending")
                }
                DrawerItem(icon: "linked", title: "Linked Bank Accounts") {
                    onSelect("linked")
                }
                sectionDivider
                Text("SETTINGS")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.5)
                    .foregroundColor(Color(hex: "174EA6"))
                    .padding(.horizontal, 28)
                    .padding(.top, 24)
                    .padding(.bottom, 14)
                
                DrawerItem(icon: "pin", title: "Change PIN") {
                    onSelect("pinChange")
                }
                DrawerItem(icon: "biometric", title: "Biometric Login") {
                    onSelect("biometric")
                }
                .overlay(
                    HStack {
                        Spacer()
                        if UserDataManager.shared.isBiometricEnabled() {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "174EA6"))
                                .font(.system(size: 14))
                                .padding(.trailing, 16)
                        }
                    }
                )
                sectionDivider
                Text("SUPPORT")
                    .font(.system(size: 14, weight: .medium))
                    .tracking(2)
                    .foregroundColor(Color(hex: "174EA6"))
                    .padding(.horizontal, 28)
                    .padding(.top, 24)
                    .padding(.bottom, 14)
                DrawerItem(icon: "bubble.left", title: "Send Feedback") {
                    onSelect("comment")
                }
                DrawerItem(icon: "exclamationmark.bubble", title: "Report an Issue") {
                    onSelect("complaint")
                }
                
                DrawerItem(icon: "phone", title: "Contact Us") {
                    makePhoneCall(phoneNumber: "+224612008699")
                }
                
                DrawerItem(icon: "terms", title: "Terms and Conditions") {
                    onSelect("terms")
                }
                DrawerItem(icon: "faq", title: "FAQs") {
                    onSelect("FAQ")
                }
                
                DrawerItem(icon: "rectangle.portrait.and.arrow.right", title: "Log Out") {
                    onSelect("logout")
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
        }
        .background(Color.white)
        .ignoresSafeArea(edges: .top)
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(Color(hex: "E1E4E8"))
            .frame(height: 1)
            .padding(.top, 10)
    }
    
    private func makePhoneCall(phoneNumber: String) {
        let cleanedNumber = phoneNumber.replacingOccurrences(of: " ", with: "")
        
        guard let url = URL(string: "tel://\(cleanedNumber)") else {
            //print("Invalid phone number")
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:]) { success in
                if success {
                    //print("Phone call initiated successfully")
                } else {
                    //print("Failed to initiate phone call")
                }
            }
        } else {
            //print("This device cannot make phone calls")
        }
    }
}

// MARK: - Preview
struct SideMenuView_Previews: PreviewProvider {
    static var previews: some View {
        SideMenuView { selection in
            //print("Selected: \(selection)")
        }
        .frame(width: 300)
        .previewLayout(.sizeThatFits)
    }
}
