//
//  TransferConfirmationDialog.swift
//  DiamaPay
//
//  Created by Bits on 28/9/2025.
//  Updated to show withdrawal fees and transfer fees with clear visual distinction
//

import SwiftUI

struct TransferConfirmationDialog: View {
    let amount: String
    let withdrawalFee: Double
    let transferFee: Double
    let total: Double
    let currency: String
    let recipientName: String
    let recipientPhone: String
    let paymentDetails: String
    let sourceType: SourceOfFunds
    let selectedWallet: SponsoringWallet?
    
    @Binding var isPresented: Bool
    let onConfirm: (String) -> Void
    let onCancel: () -> Void
    
    @State private var pin: String = ""
    @State private var showPinError = false
    @State private var pinErrorMessage = ""
    @State private var isVerifyingPin = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Confirmer le Transfert")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)
                .padding(.horizontal, 20)
                
                Divider()
                    .padding(.vertical, 16)
                
                // Transaction Details
                ScrollView {
                    VStack(spacing: 16) {
                        // Amount Section with Fees Breakdown
                        VStack(spacing: 12) {
                            DetailRowView(label: "Montant du transfert", value: formatAmount(Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0.0))
                            
                            Divider()
                                .padding(.vertical, 4)
                            
                            // Fees Breakdown Section
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Frais applicables")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                                
                                // Withdrawal Fee (if applicable)
                                if withdrawalFee > 0 {
                                    HStack {
                                        HStack(spacing: 6) {
                                            Image(systemName: "banknote")
                                                .font(.system(size: 12))
                                                .foregroundColor(.orange)
                                            Text("Frais de retrait")
                                                .font(.system(size: 13))
                                                .foregroundColor(.primary)
                                        }
                                        Spacer()
                                        Text(formatAmount(withdrawalFee))
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.orange)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                
                                // Transfer/Sending Fee
                                HStack {
                                    HStack(spacing: 6) {
                                        Image(systemName: "paperplane.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(transferFee > 0 ? .blueH : .green)
                                        Text("Frais d'envoi")
                                            .font(.system(size: 13))
                                            .foregroundColor(.primary)
                                    }
                                    Spacer()
                                    Text(transferFee > 0 ? formatAmount(transferFee) : "Gratuit")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(transferFee > 0 ? .blueH : .green)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background((transferFee > 0 ? Color.blueH : Color.green).opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            Divider()
                                .padding(.vertical, 4)
                            
                            DetailRowView(
                                label: "Total à débiter",
                                value: formatAmount(total),
                                isHighlighted: true
                            )
                        }
                        .padding(16)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(12)
                        
                        // Recipient Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Destinataire")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            DetailRowView(label: "Nom", value: recipientName)
                            DetailRowView(label: "Téléphone", value: recipientPhone)
                        }
                        .padding(16)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(12)
                        
                        // Source of Funds
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Source des fonds")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            if sourceType == .sponsor, let wallet = selectedWallet {
                                DetailRowView(label: "Type", value: "Portefeuille Sponsor")
                                DetailRowView(label: "Sponsor", value: wallet.userName)
                            } else {
                                DetailRowView(label: "Type", value: "Mon Portefeuille")
                            }
                        }
                        .padding(16)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(12)
                        
                        // Payment Details
                        if !paymentDetails.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Commentaire")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                                
                                Text(paymentDetails)
                                    .font(.system(size: 14))
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(12)
                        }
                        
                        // PIN Entry
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Code PIN")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            SecureField("Entrer le code PIN", text: $pin)
                                .keyboardType(.numberPad)
                                .font(.system(size: 16, weight: .medium))
                                .padding(.horizontal, 16)
                                .frame(height: 50)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(showPinError ? Color.red : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .onChange(of: pin) { newValue in
                                    if newValue.count > 4 { pin = String(newValue.prefix(4)) }
                                    showPinError = false
                                }
                            
                            if showPinError {
                                Text(pinErrorMessage)
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(16)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                }
                .frame(maxHeight: 400)
                
                Divider()
                    .padding(.vertical, 16)
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button(action: {
                        onCancel()
                    }) {
                        Text("Annuler")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blueH)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blueH, lineWidth: 1)
                            )
                    }
                    
                    Button(action: { validateAndConfirm() }) {
                        Group {
                            if isVerifyingPin {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Confirmer")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.greenH)
                        .cornerRadius(8)
                    }
                    .disabled(isVerifyingPin)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: 500)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 20)
        }
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "fr_FR")
        return (formatter.string(from: NSNumber(value: amount)) ?? "0") + " " + currency
    }
    
    private func validateAndConfirm() {
        showPinError = false
        
        guard pin.count == 4 else {
            pinErrorMessage = "Le PIN doit contenir exactement 4 chiffres"
            showPinError = true
            return
        }
        
        isVerifyingPin = true
        
        PinVerificationService.verify(pin: pin) { verifiedPin in
            isVerifyingPin = false
            onConfirm(verifiedPin)
        } onFailure: { message in
            isVerifyingPin = false
            pinErrorMessage = message
            showPinError = true
            pin = ""
        }
    }
}
