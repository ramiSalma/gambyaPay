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
    var title = "Confirmer la Mise à Disposition"
    var providerName = ""
    var recipientIdNumber = ""
    var mobileMoneyStyle = false
    var moneyVoucherStyle = false
    let paymentDetails: String
    let sourceType: SourceOfFunds
    let selectedWallet: SponsoringWallet?
    
    @Binding var isPresented: Bool
    let onConfirm: (String) -> Void
    let onCancel: () -> Void
    
    @State private var pin: String = ""
    @State private var isPinVisible = false
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
                VStack(alignment: moneyVoucherStyle ? .leading : .center, spacing: 8) {
                    if moneyVoucherStyle {
                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 22, weight: .semibold))
                            Text(title)
                                .font(.system(size: 22, weight: .bold))
                        }
                        Text("Verify your transaction details")
                            .font(.system(size: 16, weight: .medium))
                            .padding(.leading, 34)
                    } else {
                        Text(title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(mobileMoneyStyle ? Color(hex: "174EA6") : Color.primary)
                            .multilineTextAlignment(.center)
                    }
                }
                .foregroundColor(moneyVoucherStyle ? .white : .primary)
                .padding(.top, moneyVoucherStyle ? 20 : 24)
                .padding(.bottom, moneyVoucherStyle ? 18 : 0)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, alignment: moneyVoucherStyle ? .leading : .center)
                .background(moneyVoucherStyle ? Color(hex: "0788B9") : Color.clear)
                
                Divider()
                    .padding(.vertical, 16)
                
                // Transaction Details
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(spacing: 12) {
                            DetailRowView(
                                label: (mobileMoneyStyle || moneyVoucherStyle) ? "Amount" : "Montant",
                                value: formatAmount(Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0.0)
                            )
                            
                            // Withdrawal Fee (conditional)
                            if withdrawalFee > 0 {
                                DetailRowView(
                                    label: moneyVoucherStyle ? "Availability fee" : (mobileMoneyStyle ? "Withdrawal fee" : "Frais de retrait"),
                                    value: formatAmount(withdrawalFee)
                                )
                            }
                            
                            // Transaction/Sending Fee
                            DetailRowView(
                                label: moneyVoucherStyle ? "Voucher fee" : (mobileMoneyStyle ? "Mobile Money fee" : "Frais de mise à disposition"),
                                value: fee > 0 ? formatAmount(fee) : ((mobileMoneyStyle || moneyVoucherStyle) ? "Free" : "Gratuit")
                            )
                            
                            Divider()
                                .padding(.vertical, 4)
                            
                            // Total to Debit
                            DetailRowView(
                                label: (mobileMoneyStyle || moneyVoucherStyle) ? "Total to Debit" : "Total à débiter",
                                value: formatAmount(total),
                                isHighlighted: true
                            )
                        }
                        .padding(16)
                        .modifier(ConfirmationCardStyle(voucherStyle: moneyVoucherStyle))
                        .onAppear {
                            //print("🔍 Confirmation Dialog Values:")
                            //print("   Amount: \(amount)")
                            //print("   Withdrawal Fee: \(withdrawalFee)")
                            //print("   Transaction Fee: \(fee)")
                            //print("   Total: \(total)")
                        }
                        
                        // Recipient Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text((mobileMoneyStyle || moneyVoucherStyle) ? "Recipient Information" : "Destinataire")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            DetailRowView(label: (mobileMoneyStyle || moneyVoucherStyle) ? "Recipient" : "Nom", value: recipientName)
                            DetailRowView(label: (mobileMoneyStyle || moneyVoucherStyle) ? "Phone" : "Téléphone", value: recipientPhone)
                            if moneyVoucherStyle && !recipientIdNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                DetailRowView(label: "ID Number", value: recipientIdNumber)
                            }
                            if !providerName.isEmpty {
                                DetailRowView(label: "Provider", value: providerName)
                            }
                        }
                        .padding(16)
                        .modifier(ConfirmationCardStyle(voucherStyle: moneyVoucherStyle))
                        
                        // Source of Funds
                        VStack(alignment: .leading, spacing: 12) {
                            Text((mobileMoneyStyle || moneyVoucherStyle) ? "Source of Funds" : "Source des fonds")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            if sourceType == .sponsor, let wallet = selectedWallet {
                                DetailRowView(label: "Type", value: (mobileMoneyStyle || moneyVoucherStyle) ? "Sponsor wallet" : "Portefeuille Sponsor")
                                DetailRowView(label: "Sponsor", value: wallet.userName)
                            } else {
                                DetailRowView(label: "Type", value: (mobileMoneyStyle || moneyVoucherStyle) ? "My wallet" : "Mon Portefeuille")
                            }
                        }
                        .padding(16)
                        .modifier(ConfirmationCardStyle(voucherStyle: moneyVoucherStyle))
                        
                        // Payment Details
                        if !paymentDetails.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text((mobileMoneyStyle || moneyVoucherStyle) ? "Reason" : "Commentaire")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                                
                                Text(paymentDetails)
                                    .font(.system(size: 14))
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .modifier(ConfirmationCardStyle(voucherStyle: moneyVoucherStyle))
                        }
                        
                        // PIN Entry
                        VStack(alignment: .leading, spacing: 12) {
                            Text((mobileMoneyStyle || moneyVoucherStyle) ? "Authentication" : "Code PIN")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 14) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor((mobileMoneyStyle || moneyVoucherStyle) ? Color(hex: "0788B9") : .blueH)
                                Group {
                                    if isPinVisible {
                                        TextField((mobileMoneyStyle || moneyVoucherStyle) ? "PIN Code" : "Entrer le code PIN", text: $pin)
                                    } else {
                                        SecureField((mobileMoneyStyle || moneyVoucherStyle) ? "PIN Code" : "Entrer le code PIN", text: $pin)
                                    }
                                }
                                .keyboardType(.numberPad)
                                .font(.system(size: 16, weight: .medium))
                                Button { isPinVisible.toggle() } label: {
                                    Image(systemName: isPinVisible ? "eye" : "eye.slash")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 56)
                            .background(Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(showPinError ? Color.red : Color.gray.opacity(0.65), lineWidth: 1.2))
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
                        .modifier(ConfirmationCardStyle(voucherStyle: moneyVoucherStyle))
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
                        Text((mobileMoneyStyle || moneyVoucherStyle) ? "Cancel" : "Annuler")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(moneyVoucherStyle ? .white : .blueH)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(moneyVoucherStyle ? Color(hex: "0788B9") : Color.white)
                            .cornerRadius(moneyVoucherStyle ? 12 : 8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(moneyVoucherStyle ? Color(hex: "0788B9") : (mobileMoneyStyle ? Color(hex: "174EA6") : Color.blueH), lineWidth: 1)
                            )
                    }
                    
                    Button(action: { validateAndConfirm() }) {
                        Group {
                            if isVerifyingPin {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(moneyVoucherStyle ? "Transfer" : (mobileMoneyStyle ? "Confirm" : "Confirmer"))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background((mobileMoneyStyle || moneyVoucherStyle) ? Color(hex: "0788B9") : Color.greenH)
                        .cornerRadius(moneyVoucherStyle ? 12 : 8)
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
            pinErrorMessage = (mobileMoneyStyle || moneyVoucherStyle) ? "PIN must contain exactly 4 digits" : "Le PIN doit contenir exactement 4 chiffres"
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

private struct ConfirmationCardStyle: ViewModifier {
    let voucherStyle: Bool

    func body(content: Content) -> some View {
        content
            .background(voucherStyle ? Color(hex: "F8F9FB") : Color(UIColor.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: voucherStyle ? 14 : 12))
            .overlay(RoundedRectangle(cornerRadius: voucherStyle ? 14 : 12)
                .stroke(voucherStyle ? Color(hex: "E1E5EB") : Color.clear, lineWidth: 1.2))
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
                .foregroundColor(isHighlighted ? Color(hex: "263445") : Color(hex: "667085"))
            
            Spacer()
            
            Text(value)
                .font(.system(size: isHighlighted ? 16 : 14, weight: isHighlighted ? .bold : .semibold))
                .foregroundColor(isHighlighted ? Color(hex: "174EA6") : Color(hex: "263445"))
        }
    }
}
