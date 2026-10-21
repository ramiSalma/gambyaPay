import SwiftUI

struct FAQView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    @State private var expandedIndex: Int? = nil
    
    // Frequently asked questions
    let faqs: [(question: String, answer: String)] = [
        // General
        ("What is GambiaPay?", "GambiaPay is your secure digital wallet for managing payments, transfers, and top-ups."),
        ("How do I register for GambiaPay?", "Download the GambiaPay app from the Apple App Store or Google Play, open it, tap Sign Up, and follow the instructions."),
        ("How do I log in to GambiaPay?", "Open the GambiaPay app, enter your phone number and PIN, then tap Log In."),
        ("I forgot my PIN code. What should I do?", "Contact customer support with a valid form of identification to answer the security questions and begin resetting your PIN."),
        
        // Balance and account
        ("How do I check my GambiaPay wallet balance?", "Your balance appears when you log in. If it is hidden by asterisks (*), tap the eye icon to show it."),
        ("Why does my balance show as asterisks (*)?", "Your balance is hidden for security. Tap the eye icon to show it."),
        ("How do I check my transaction history?", "After logging in, tap See More below your balance to view your transactions from the last 30 days."),
        
        // Transfers
        ("How do I send money?", "Tap Internal Transfer, then follow these steps:\n1. Choose the funding source\n2. Enter the recipient's 9-digit phone number\n3. Verify the recipient\n4. Enter the amount\n5. Select Add Fees if needed\n6. Add an optional comment\n7. Review the transfer\n8. Enter your PIN\n9. Confirm the transfer."),
        ("How do I link my GambiaPay wallet to my bank account?", "Visit a branch of your bank with valid identification to request a wallet link."),
        ("How do I add money to my GambiaPay wallet from my bank account?", "Tap Top Up My Wallet, then select your account, enter the amount, add an optional reference, review the transfer, enter your PIN, and confirm."),
        ("How do I transfer money from my GambiaPay wallet to my bank account?", "Tap To My Bank, select your account, enter the amount, add an optional reference, review the transfer, enter your PIN, and confirm."),
        ("How often is my balance updated?", "Your balance updates in real time whenever you open or manually refresh the app."),
        
        // Transfer types
        ("What types of transfers can I make?", "• Wallet to wallet\n• Wallet to bank account\n• Bank account to wallet\n• Mobile money through partner services"),
        ("Are there limits on how much I can transfer?", "Yes. Limits depend on your account type and verification level. Contact support for details."),
        ("How long do transfers take?", "Most wallet-to-wallet transfers are instant."),
        
        // Payments and services
        ("Can I buy phone credit in the app?", "Yes. You can buy phone credit for yourself or someone else in the app."),
        ("Can I buy data bundles?", "The app lets you buy internet bundles for several mobile networks."),
        ("Can I pay bills with GambiaPay?", "Yes. You can use the app to pay utility and other bills."),
        ("What is a cash voucher?", "Cash vouchers let you create a code that someone else can redeem for money."),
        
        // More features
        ("What are standing instructions?", "They let you schedule recurring automatic transfers, such as monthly payments."),
        ("What are sponsored wallets?", "They let users sponsor another user or be sponsored to share funds."),
        ("What is a savings wallet?", "It helps you set money aside separately from your main balance."),
        ("How do I view recent transactions?", "Open Mini Statement from the menu to see your recent transactions."),
        
        // Security
        ("Is my money safe in the app?", "Yes. GambiaPay uses encryption and security protocols to help protect your account."),
        ("Can I change my PIN?", "Yes. Open the menu and select Change PIN."),
        ("What should I do if someone accesses my account without permission?", "Change your PIN immediately, review your transactions, and contact support."),
        ("How do I deactivate my wallet?", "Select Deactivate Wallet from the menu. This action may be irreversible."),
        
        // Customer support
        ("How do I contact customer support?", "• Call 0612 00 86 99\n• Use Contact Us in the app\n• Send feedback from the app menu."),
        ("How do I report a problem?", "Select Report a Problem from the navigation menu."),
        ("Can I send feedback about the app?", "Yes. Select Send Feedback from the menu."),
        
        // Troubleshooting
        ("The app won't load my balance. What should I do?", "1. Check your internet connection\n2. Restart the app\n3. Tap the eye icon to refresh\n4. Contact support if the problem continues."),
        ("I'm having problems with transfers. What could be wrong?", "Check your balance, internet connection, recipient's number, and transfer limits."),
        ("How do I update the app?", "Check the App Store or Google Play for the latest version."),
        ("The app crashes frequently. What should I do?", "1. Restart your device\n2. Clear the app cache\n3. Update the app\n4. Contact support if the problem continues."),
        
        // Account
        ("How do I log out of the app?", "Open the menu and select Log Out."),
        ("Can I use the app on multiple devices?", "Yes, but you will need to verify with a one-time password when logging in on a new device."),
        ("What happens if I uninstall the app?", "Your funds remain safe. Reinstall the app to access your wallet again."),
        
        // Fees
        ("Are there fees for using the app?", "Some transactions may have fees. Contact customer support for details.")
    ]
    
    // --- Filtrage FAQ ---
    var filteredFaqs: [(question: String, answer: String)] {
        if searchText.isEmpty {
            return faqs
        } else {
            return faqs.filter {
                $0.question.localizedCaseInsensitiveContains(searchText) ||
                $0.answer.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGray6)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ZStack {
                    Color(hex: "174EA6")
                    HStack(spacing: 12) {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 44, alignment: .leading)
                        }
                        Spacer(minLength: 0)
                        Text("Frequently Asked Questions")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        Spacer(minLength: 0)
                        Color.clear.frame(width: 40, height: 44)
                    }
                    .padding(.horizontal, 20)
                }
                .frame(height: 54)
                .background(Color(hex: "174EA6").ignoresSafeArea(edges: .top))

                
                ScrollView {
                    VStack(spacing: 14) {
                        
                        // Search
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .font(.system(size: 17))
                            
                            TextField("Search...", text: $searchText)
                                .font(.system(size: 15))
                            
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 16))
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.07), lineWidth: 1))
                        .padding(.horizontal, 14)
                        .padding(.top, 12)
                        
                        // Quick help cards
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Need help?")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 14)
                            
                            HStack(spacing: 12) {
                                // Contact Card
                                VStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: "F1F8F2"))
                                            .frame(width: 42, height: 42)
                                        
                                        Image(systemName: "phone.fill")
                                            .font(.system(size: 17))
                                            .foregroundColor(Color(hex: "0788B9"))
                                    }
                                    
                                    VStack(spacing: 3) {
                                        Text("Contact Us")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.black)
                                        
                                        Text("+224 612 00 86 99")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Color(hex: "0788B9"))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(Color.white)
                                .cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black.opacity(0.07), lineWidth: 1))
                                
                                // Commentaires Card
                                VStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: "F1F8F2"))
                                            .frame(width: 42, height: 42)
                                        
                                        Image(systemName: "bubble.left.fill")
                                            .font(.system(size: 17))
                                            .foregroundColor(Color(hex: "174EA6"))
                                    }
                                    
                                    VStack(spacing: 3) {
                                        Text("Feedback")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.black)
                                        
                                        Text("Give your opinion")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Color(hex: "174EA6"))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(Color.white)
                                .cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black.opacity(0.07), lineWidth: 1))
                            }
                            .padding(.horizontal, 14)
                        }
                        
                        // Questions and answers
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Questions & Answers")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.black)
                                
                                Spacer()
                                
                                if !filteredFaqs.isEmpty {
                                    Text("\(filteredFaqs.count)")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.blueH)
                                        .cornerRadius(18)
                                }
                            }
                            .padding(.horizontal, 14)
                            
                            if filteredFaqs.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 30))
                                        .foregroundColor(.gray.opacity(0.5))
                                    
                                    Text("No results found")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)
                                    
                                    Text("Try another search")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray.opacity(0.7))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                            } else {
                                VStack(spacing: 10) {
                                    ForEach(filteredFaqs.indices, id: \.self) { index in
                                        DisclosureGroup(
                                            isExpanded: Binding(
                                                get: { expandedIndex == index },
                                                set: { expandedIndex = $0 ? index : nil }
                                            )
                                        ) {
                                            Text(filteredFaqs[index].answer)
                                                .font(.system(size: 14))
                                                .foregroundColor(Color(hex: "475467"))
                                                .padding(.top, 8)
                                                .padding(.bottom, 12)
                                                .fixedSize(horizontal: false, vertical: true)
                                        } label: {
                                            HStack {
                                                Text(filteredFaqs[index].question)
                                                    .font(.system(size: 15, weight: .semibold))
                                                    .foregroundColor(Color(hex: "263445"))
                                                    .multilineTextAlignment(.leading)
                                                    .fixedSize(horizontal: false, vertical: true)
                                                
                                                Spacer()
                                            }
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                        .background(Color.white)
                                        .cornerRadius(12)
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.07), lineWidth: 1))
                                    }
                                }
                                .padding(.horizontal, 14)
                            }
                        }
                        
                        // Help footer
                        VStack(spacing: 12) {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(Color(hex: "174EA6"))
                            
                            Text("Need additional help?")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text("Our team is available 24/7 to help you")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AppBottomBar(onSponsors: {}, onQR: {}, onLimits: {}, onSettings: {})
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationView { FAQView() }
}
