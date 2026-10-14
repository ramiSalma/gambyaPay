//
//  VoucherConfirmationDialog.swift
//  DiamaPay
//
//  Created by Bits on 30/9/2025.
//

import SwiftUI

struct VoucherConfirmationDialog: View {
    let amount: String
    let withdrawalFee: Double
    let fee: Double
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
    @State private var isVerifyingPin = false
    @State private var pinErrorMessage = ""
    
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
                
                    
                    Text("Confirmer la Mise à Disposition")
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
                        VStack(spacing: 12) {
                            DetailRowView(
                                label: "Montant",
                                value: formatAmount(Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0.0)
                            )
                            
                            // Withdrawal Fee (conditional)
                            if withdrawalFee > 0 {
                                DetailRowView(
                                    label: "Frais de retrait",
                                    value: formatAmount(withdrawalFee)
                                )
                            }
                            
                            // Transaction/Sending Fee
                            DetailRowView(
                                label: "Frais de mise à disposition",
                                value: fee > 0 ? formatAmount(fee) : "Gratuit"
                            )
                            
                            Divider()
                                .padding(.vertical, 4)
                            
                            // Total to Debit
                            DetailRowView(
                                label: "Total à débiter",
                                value: formatAmount(total),
                                isHighlighted: true
                            )
                        }
                        .padding(16)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(12)
                        .onAppear {
                            //print("🔍 Confirmation Dialog Values:")
                            //print("   Amount: \(amount)")
                            //print("   Withdrawal Fee: \(withdrawalFee)")
                            //print("   Transaction Fee: \(fee)")
                            //print("   Total: \(total)")
                        }
                        
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

struct DetailRowView: View {
    let label: String
    let value: String
    var isHighlighted: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: isHighlighted ? 16 : 14, weight: isHighlighted ? .semibold : .regular))
                .foregroundColor(isHighlighted ? .primary : .secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: isHighlighted ? 16 : 14, weight: isHighlighted ? .bold : .semibold))
                .foregroundColor(isHighlighted ? .greenH : .primary)
        }
    }
}
