//
//  BillPayProvidersView.swift
//  DiamaPay
//
//  Bill Payment Providers Selection
//

import SwiftUI

struct BillPayProvidersView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var navigateToDSD = false
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                DiamaPayHeader(title: "Bill Payments", headerColor: Color(hex: "174EA6"))
                
                ScrollView {
                    VStack(spacing: 16) {
                        // DSD Payment Provider Card
                        ProviderCard(
                            title: "DSD",
                            subtitle: "Direction de la Sécurité Douanière",
                            icon: "dsd",
                            color: .blueH
                        ) {
                            navigateToDSD = true
                        }
                        
                        // Add more providers here as needed
                        // ProviderCard(title: "Provider 2", ...)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AppBottomBar(onSponsors: {}, onQR: {}, onLimits: {}, onSettings: {})
        }
        .navigationBarHidden(true)
        .background(
            NavigationLink(
                destination: DSDBillTypesView(),  // Navigate to bill types first
                isActive: $navigateToDSD
            ) {
                EmptyView()
            }
            .hidden()
        )
    }
}

// MARK: - Provider Card Component
struct ProviderCard: View {
    let title: String
    let subtitle: String
    let icon: String  // Can be SF Symbol name, image URL, or asset name
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon - No background circle for assets
                if let _ = UIImage(named: icon) {
                    // Local asset image
                    Image(icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 56, height: 56)
                } else if icon.hasPrefix("http://") || icon.hasPrefix("https://") {
                    // Remote image
                    AsyncImage(url: URL(string: icon)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 56, height: 56)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 56, height: 56)
                        case .failure:
                            // Fallback to colored circle with icon
                            ZStack {
                                Circle()
                                    .fill(color.opacity(0.1))
                                    .frame(width: 56, height: 56)
                                Image(systemName: "photo")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(color)
                            }
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    // SF Symbol with colored background
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.1))
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(color)
                    }
                }
                
                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gray)
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct BillPayProvidersView_Previews: PreviewProvider {
    static var previews: some View {
        BillPayProvidersView()
    }
}
