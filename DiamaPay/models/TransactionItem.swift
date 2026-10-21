//
//  TransactionItem.swift
//  DiamaPay
//
//  Created by Bits on 1/10/2025.
//


//
//  TransactionItem.swift
//  DiamaPay
//
//  Created by Bits on [Date]
//

import Foundation

struct TransactionItem: Identifiable, Codable {
    var id: String = UUID().uuidString
    
    var transactionReference: String?
    var transactionDate: String?
    var amount: String?
    var status: String?
    var currency: String?
    var sign: String? // "D" for debit, "C" for credit
    var type: String?
    var details: String?
    var openingBalance: String?
    var closingBalance: String?
    
    enum CodingKeys: String, CodingKey {
        case transactionReference = "trxRef"
        case transactionDate = "authDate"
        case amount
        case status
        case currency
        case sign
        case type
        case details = "trxDetails"
        case openingBalance = "openBalance"
        case closingBalance = "closeBalance"
    }
    
    // Computed properties
    var isDebit: Bool {
        return sign == "D"
    }
    
    var isCredit: Bool {
        return sign == "C"
    }
    
    var formattedAmount: String {
        guard let amount = amount, let currency = currency else {
            return "0.00"
        }
        
        let prefix = isDebit ? "-" : (isCredit ? "+" : "")
        return "\(prefix)\(amount) \(currency)"
    }
    
    var cleanDescription: String {
        if let details = details, !details.trimmingCharacters(in: .whitespaces).isEmpty {
            // For received transfers
            if details.contains("Received transfer from:") {
                if let phoneNumber = extractPhoneNumber(from: details, pattern: "Received transfer from:\\s*(\\d+)") {
                    return "Transfert reçu de \(maskPhoneNumber(phoneNumber))"
                }
            }
            
            // For sent transfers
            if details.contains("Transfer to:") {
                if let phoneNumber = extractPhoneNumber(from: details, pattern: "Transfer to:\\s*(\\d+)") {
                    return "\(frenchTransactionType) \(maskPhoneNumber(phoneNumber))"
                }
            }
            
            // For acquiring entity
            if details.contains("Acquiring entity :") {
                if let entityId = extractPhoneNumber(from: details, pattern: "Acquiring entity :\\s*(\\d+)") {
                    return "\(frenchTransactionType) via \(maskEntityId(entityId))"
                }
            }
            
            // For institution transfers
            if details.contains("institution:") {
                if let institution = extractPhoneNumber(from: details, pattern: "institution:\\s*([^,]+)") {
                    return "\(frenchTransactionType) via \(institution.trimmingCharacters(in: .whitespaces))"
                }
            }
            
            // Extract reason
            if details.contains("reason :") {
                let parts = details.components(separatedBy: "reason :")
                if parts.count > 1 {
                    let reason = parts[1].components(separatedBy: ",")[0].trimmingCharacters(in: .whitespaces)
                    if !reason.isEmpty && reason != "edd" && reason != "reff" {
                        return "\(frenchTransactionType) - \(reason)"
                    }
                }
            }
        }
        
        return frenchTransactionType
    }
    
    var frenchTransactionType: String {
        guard let type = type else { return "Transaction" }
        
        switch type.uppercased() {
        case "CASH OUT": return "Retrait d'espèces"
        case "CASH IN": return "Dépôt d'espèces"
        case "ACCOUNT TO WALLET": return "Compte vers portefeuille"
        case "TOPUP PURCHASE": return "Achat de crédit"
        case "EVALUE CREDIT": return "Crédit eValue"
        case "EVALUE DEBIT": return "Débit eValue"
        case "EVALUE_TRANSFER": return "Transfert eValue"
        case "TELLER CASH OUT": return "Retrait guichet"
        case "TELLER CASH IN": return "Dépôt guichet"
        case "GIP QR CREDIT": return "Crédit QR GIP"
        case "GIP QR DEBIT": return "Débit QR GIP"
        case "WALLET TO WALLET": return "Transfert entre portefeuilles"
        case "MONEY VOUCHER": return "Bon d'argent"
        case "MONEY VOUCHER TRANSFER": return "Transfert bon d'argent"
        case "QR TRANSFER": return "Transfert QR"
        case "WALLET TO ACCOUNT": return "Portefeuille vers compte"
        case "AGENT CASH IN": return "Dépôt agent"
        case "AGENT CASH OUT": return "Retrait agent"
        case "AGENT MONEY VOUCHER CASH": return "Espèces bon agent"
        case "GIP CREDIT": return "Crédit GIP"
        case "GIP DEBIT": return "Débit GIP"
        case "MOBILE MONEY": return "Argent mobile"
        case "REQUEST TO PAY": return "Demande de paiement"
        case "BILLER PAYMENT ACCOUNT": return "Paiement facture compte"
        case "BILLER PAYMENT WALLET": return "Paiement facture portefeuille"
        case "BILL PAYMENT": return "Paiement de facture"
        case "WALLET ENQUIRY": return "Consultation portefeuille"
        case "SAVING TRANSACTION": return "Transaction épargne"
        case "SAVING DAILY INTERESTS": return "Intérêts quotidiens épargne"
        case "SAVING DAILY INTERESTS REV": return "Annulation intérêts épargne"
        case "SAVING INTERESTS": return "Intérêts épargne"
        case "INTEREST CREDIT": return "Crédit d'intérêts"
        case "INTEREST TRANSACTION": return "Transaction d'intérêts"
        case "SPONSORED TRANSACTION": return "Transaction sponsorisée"
        case "CREDIT AGENT COMISSION": return "Commission agent"
        case "DORMANT WALLET TO UNCLAIMED": return "Portefeuille dormant"
        case "DORMANT SAVINGS TO UNCLAIMED": return "Épargne dormante"
        case "BRANCH PORTING": return "Portage agence"
        case "WALLET PORTING": return "Portage portefeuille"
        case "TRANSFER TO WALLET": return "Transfert vers portefeuille"
        case "TRANSFER FROM WALLET": return "Transfert depuis portefeuille"
        default: return type
        }
    }
    
    // Helper methods
    private func extractPhoneNumber(from text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }
        
        let range = NSRange(text.startIndex..., in: text)
        if let match = regex.firstMatch(in: text, options: [], range: range),
           match.numberOfRanges > 1 {
            let matchRange = match.range(at: 1)
            if let swiftRange = Range(matchRange, in: text) {
                return String(text[swiftRange])
            }
        }
        
        return nil
    }
    
    private func maskPhoneNumber(_ phoneNumber: String) -> String {
        guard phoneNumber.count >= 7 else { return phoneNumber }
        let start = phoneNumber.prefix(4)
        let end = phoneNumber.suffix(3)
        return "\(start)****\(end)"
    }
    
    private func maskEntityId(_ entityId: String) -> String {
        guard entityId.count >= 6 else { return "Agent" }
        let end = entityId.suffix(3)
        return "***\(end)"
    }
}