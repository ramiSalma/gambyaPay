//
//  DrawerItem.swift
//  DiamaPay
//
//  Created by Bits on 18/9/2025.
//

import SwiftUI

struct DrawerItem: View {
    var icon: String
    var title: String
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                // Handle biometric icon dynamically based on device
                if icon == "biometric" {
                    Image(systemName: BiometricHelper.getBiometricType().icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundColor(Color(hex: "0756A7"))
                }
                // Try to load system icon first, otherwise fallback to asset
                else if UIImage(systemName: icon) != nil {
                    Image(systemName: icon)
                        .font(.system(size: 25, weight: .regular))
                        .frame(width: 28, height: 28)
                        .foregroundColor(Color(hex: "0756A7"))
                } else {
                    Image(icon) // Loads from Assets
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundColor(Color(hex: "0756A7"))
                }
                
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(hex: "394353"))
                    .padding(.leading, 14)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                
                Spacer()
                
            }
            .frame(minHeight: 70)
            .padding(.vertical, 4)
            .padding(.horizontal, 26)
        }
        .buttonStyle(.plain)
    }
}
