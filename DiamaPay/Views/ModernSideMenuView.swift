//
//  ModernSideMenuView.swift
//  DiamaPay
//
//  Created by Bits on 31/10/2025.
//


import SwiftUI

struct ModernSideMenuView: View {
    var onSelect: (String) -> Void
    @State private var selectedItem: String? = nil
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Modern gradient header
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blueH, Color.blueH.opacity(0.8)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "wallet.pass.fill")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        
                        Text("DIAMACASH")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Votre portefeuille digital sécurisé")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .padding(.top, 50)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 160)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                
                // Menu sections
                VStack(spacing: 0) {
                    // TRANSFERT Section
                    MenuSection(title: "TRANSFERT") {
                        ModernDrawerItem(
                            icon: "arrow.left.arrow.right",
                            title: "Transférer de l'argent",
                            iconColor: .blue,
                            isSelected: selectedItem == "walletTransfer"
                        ) {
                            selectedItem = "walletTransfer"
                            onSelect("walletTransfer")
                        }
                        
                        ModernDrawerItem(
                            icon: "wallet.bifold.fill",
                            title: "Wallet vers ma Banque",
                            iconColor: .purple,
                            isSelected: selectedItem == "walletToAccountTransfer"
                        ) {
                            selectedItem = "walletToAccountTransfer"
                            onSelect("walletToAccountTransfer")
                        }
                        
                        ModernDrawerItem(
                            icon: "building.columns.fill",
                            title: "Banque vers mon Wallet",
                            iconColor: .orange,
                            isSelected: selectedItem == "accountToWalletTransfer"
                        ) {
                            selectedItem = "accountToWalletTransfer"
                            onSelect("accountToWalletTransfer")
                        }
                        
                        ModernDrawerItem(
                            icon: "ticket.fill",
                            title: "Mise à disposition",
                            iconColor: .green,
                            isSelected: selectedItem == "moneyVoucher"
                        ) {
                            selectedItem = "moneyVoucher"
                            onSelect("moneyVoucher")
                        }
                        
                        ModernDrawerItem(
                            icon: "qrcode",
                            title: "Paiement QR",
                            iconColor: .indigo,
                            isSelected: selectedItem == "qr"
                        ) {
                            selectedItem = "qr"
                            onSelect("qr")
                        }
                        
                        ModernDrawerItem(
                            icon: "repeat",
                            title: "Virements Permanents",
                            iconColor: .teal,
                            isSelected: selectedItem == "si"
                        ) {
                            selectedItem = "si"
                            onSelect("si")
                        }
                    }
                    
                    // PARRAINAGE Section
                    MenuSection(title: "PARRAINAGE") {
                        ModernDrawerItem(
                            icon: "person.2.fill",
                            title: "Portefeuilles parrainés",
                            iconColor: .pink,
                            isSelected: selectedItem == "sponsored"
                        ) {
                            selectedItem = "sponsored"
                            onSelect("sponsored")
                        }
                        
                        ModernDrawerItem(
                            icon: "person.3.fill",
                            title: "Afficher mes parrains",
                            iconColor: .cyan,
                            isSelected: selectedItem == "sponsoring"
                        ) {
                            selectedItem = "sponsoring"
                            onSelect("sponsoring")
                        }
                    }
                    
                    // GESTION DU PORTEFEUILLE Section
                    MenuSection(title: "GESTION DU PORTEFEUILLE") {
                        ModernDrawerItem(
                            icon: "gauge.with.needle.fill",
                            title: "Mes limites",
                            iconColor: .yellow,
                            isSelected: selectedItem == "limits"
                        ) {
                            selectedItem = "limits"
                            onSelect("limits")
                        }
                        
                        ModernDrawerItem(
                            icon: "doc.text.fill",
                            title: "Demande de mini-relevé",
                            iconColor: .blue,
                            isSelected: selectedItem == "statement"
                        ) {
                            selectedItem = "statement"
                            onSelect("statement")
                        }
                        
                        ModernDrawerItem(
                            icon: "xmark.circle.fill",
                            title: "Désactiver mon compte",
                            iconColor: .red,
                            isSelected: selectedItem == "deactivate"
                        ) {
                            selectedItem = "deactivate"
                            onSelect("deactivate")
                        }
                        
                        ModernDrawerItem(
                            icon: "hourglass",
                            title: "Transaction à valider",
                            iconColor: .orange,
                            isSelected: selectedItem == "pending"
                        ) {
                            selectedItem = "pending"
                            onSelect("pending")
                        }
                        
                        ModernDrawerItem(
                            icon: "link.circle.fill",
                            title: "Comptes Bancaires",
                            iconColor: .purple,
                            isSelected: selectedItem == "linked"
                        ) {
                            selectedItem = "linked"
                            onSelect("linked")
                        }
                    }
                    
                    // PARAMETRE Section
                    MenuSection(title: "PARAMETRE") {
                        ModernDrawerItem(
                            icon: "lock.rotation.open",
                            title: "Changer le code PIN",
                            iconColor: .indigo,
                            isSelected: selectedItem == "pinChange"
                        ) {
                            selectedItem = "pinChange"
                            onSelect("pinChange")
                        }
                        
                        HStack {
                            ModernDrawerItem(
                                icon: "faceid",
                                title: "Connexion biométrique",
                                iconColor: .green,
                                isSelected: selectedItem == "biometric"
                            ) {
                                selectedItem = "biometric"
                                onSelect("biometric")
                            }
                            
                            if UserDataManager.shared.isBiometricEnabled() {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 20, weight: .semibold))
                                    .padding(.trailing, 24)
                            }
                        }
                    }
                    
                    // ASSISTANCE Section
                    MenuSection(title: "ASSISTANCE") {
                        ModernDrawerItem(
                            icon: "text.bubble.fill",
                            title: "Écrire un commentaire",
                            iconColor: .blue,
                            isSelected: selectedItem == "comment"
                        ) {
                            selectedItem = "comment"
                            onSelect("comment")
                        }
                        
                        ModernDrawerItem(
                            icon: "exclamationmark.triangle.fill",
                            title: "Déclarer un incident",
                            iconColor: .orange,
                            isSelected: selectedItem == "complaint"
                        ) {
                            selectedItem = "complaint"
                            onSelect("complaint")
                        }
                        
                        ModernDrawerItem(
                            icon: "phone.fill",
                            title: "Contactez-nous",
                            iconColor: .green,
                            isSelected: selectedItem == "contact"
                        ) {
                            selectedItem = "contact"
                            makePhoneCall(phoneNumber: "+224612008699")
                        }
                        
                        ModernDrawerItem(
                            icon: "doc.plaintext.fill",
                            title: "Conditions générales",
                            iconColor: .gray,
                            isSelected: selectedItem == "terms"
                        ) {
                            selectedItem = "terms"
                            onSelect("complaint")
                        }
                        
                        ModernDrawerItem(
                            icon: "questionmark.circle.fill",
                            title: "FAQ",
                            iconColor: .cyan,
                            isSelected: selectedItem == "FAQ"
                        ) {
                            selectedItem = "FAQ"
                            onSelect("FAQ")
                        }
                    }
                    
                    // Logout - Special styling
                    Divider()
                        .padding(.vertical, 8)
                    
                    Button(action: {
                        selectedItem = "logout"
                        onSelect("logout")
                    }) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.red.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.red)
                            }
                            
                            Text("Déconnexion")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.red)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            selectedItem == "logout" ?
                            Color.red.opacity(0.08) : Color.clear
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                        .frame(height: 40)
                }
            }
            .background(Color(.systemGroupedBackground))
        }
        .background(Color(.systemGroupedBackground))
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

// MARK: - Modern Section Header
struct MenuSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 8)
            
            content
            
            Divider()
                .padding(.vertical, 8)
        }
    }
}

// MARK: - Modern Drawer Item
struct ModernDrawerItem: View {
    let icon: String
    let title: String
    let iconColor: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blueH.opacity(0.08) : Color.clear)
                    .padding(.horizontal, 16)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}


// MARK: - Preview
struct ModernSideMenuView_Previews: PreviewProvider {
    static var previews: some View {
        ModernSideMenuView { selection in
            //print("Selected: \(selection)")
        }
        .frame(width: 340)
    }
}
