import SwiftUI
import PDFKit

struct QRPaymentSuccessView: View {
    let transactionId: String
    let transactionDate: String
    let amount: String
    let merchantName: String
    let merchantWallet: String
    let merchantNumber: String
    let bankCode: String
    let senderName: String
    let senderPhone: String
    let sendingFee: Double  // ✅ Already filtered by recipient type
    let withdrawalFee: Double  // ✅ Already filtered by recipient type
    let total: Double
    let currency: String
    let paymentDetails: String
    let recipientType: RecipientType
    let onClose: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                        .padding(.top, 20)
                    
                    Text("Paiement réussi")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    // DETAILS CARD
                    VStack(alignment: .leading, spacing: 16) {
                        Group {
                            DetailRow(label: "ID Transaction:", value: transactionId)
                            DetailRow(label: "Date:", value: transactionDate)
                            DetailRow(label: "Montant :",
                                      value: formatAmount(Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0.0))
                            
                            // ✅ Show fees if they exist (already filtered)
                            if sendingFee > 0 {
                                DetailRow(
                                    label: "Frais d'envoi:",
                                    value: formatAmount(sendingFee),
                                    valueColor: .orange
                                )
                            }
                            
                            if withdrawalFee > 0 {
                                DetailRow(
                                    label: "Frais de retrait:",
                                    value: formatAmount(withdrawalFee),
                                    valueColor: .orange
                                )
                            }
                            
                            Divider().padding(.vertical, 4)
                            
                            DetailRow(
                                label: "Total débité:",
                                value: formatAmount(total),
                                valueColor: .primary,
                                isBold: true
                            )
                        }
                        
                        Divider().padding(.vertical, 8)
                        
                        Group {
                            DetailRow(label: "Émetteur:", value: senderName)
                            DetailRow(label: "Téléphone:", value: senderPhone)
                        }
                        
                        Divider().padding(.vertical, 8)
                        
                        Group {
                            DetailRow(label: "Destinataire:", value: merchantName)
                            
                            if recipientType != .unknown {
                                HStack {
                                    Text("Type:")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(recipientTypeName)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(recipientTypeColor)
                                        .cornerRadius(4)
                                }
                            }

                            DetailRow(label: "Portefeuille:", value: merchantWallet)
                            
                            if !merchantNumber.isEmpty {
                                DetailRow(label: "ID Destinataire:", value: merchantNumber)
                            }
                            
                            if !bankCode.isEmpty {
                                DetailRow(label: "Banque:", value: bankCode)
                            }
                            
                            if !paymentDetails.isEmpty {
                                DetailRow(label: "Détails:", value: paymentDetails)
                            }
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // ACTION BUTTONS
                    VStack(spacing: 12) {
                        Button(action: { shareReceipt() }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Partager le reçu")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.blueH)
                            .cornerRadius(8)
                        }
                        
                        Button(action: onClose) {
                            Text("Fermer")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.blueH)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.blueH.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .navigationBarItems(trailing: Button("Fermer", action: onClose))
            .navigationBarTitle("Reçu de paiement QR", displayMode: .inline)
        }
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "fr_FR")
        return (formatter.string(from: NSNumber(value: amount)) ?? "0") + " " + currency
    }
    
    private var recipientTypeName: String {
        switch recipientType {
        case .client: return "CLIENT"
        case .merchant: return "MARCHAND"
        case .agent: return "AGENT"
        case .unknown: return "INCONNU"
        }
    }
    
    private var recipientTypeColor: Color {
        switch recipientType {
        case .client: return .blue
        case .merchant: return .green
        case .agent: return .orange
        case .unknown: return .gray
        }
    }
    
    private func shareReceipt() {
        let pdfData = generatePDF()
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("Recu_Paiement_QR_\(transactionId).pdf")
        
        do {
            try pdfData.write(to: fileURL)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootVC = windowScene.windows.first?.rootViewController else { return }
                
                var topVC = rootVC
                while let presented = topVC.presentedViewController {
                    topVC = presented
                }
                
                let activityVC = UIActivityViewController(
                    activityItems: [fileURL, generateReceiptText()],
                    applicationActivities: nil
                )
                
                if let pop = activityVC.popoverPresentationController {
                    pop.sourceView = topVC.view
                    pop.sourceRect = CGRect(
                        x: topVC.view.bounds.midX,
                        y: topVC.view.bounds.midY,
                        width: 0,
                        height: 0
                    )
                    pop.permittedArrowDirections = []
                }
                
                topVC.present(activityVC, animated: true)
            }
            
        } catch {
        }
    }
    
    private func generatePDF() -> Data {
        let pdfMeta = [
            kCGPDFContextCreator: "DIAMACASH",
            kCGPDFContextAuthor: senderName,
            kCGPDFContextTitle: "Reçu de Paiement QR EMV"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMeta as [String: Any]
        
        let pageWidth: CGFloat = 595
        let pageHeight: CGFloat = 842
        let margin: CGFloat = 50
        
        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight),
            format: format
        )
        
        return renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = margin
            let contentWidth = pageWidth - (2 * margin)
            
            func addText(_ text: String, fontSize: CGFloat = 12, isBold: Bool = false, color: UIColor = .black, extraSpacing: CGFloat = 5) {
                let font = isBold ? UIFont.boldSystemFont(ofSize: fontSize) : UIFont.systemFont(ofSize: fontSize)
                
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineBreakMode = .byWordWrapping
                
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color,
                    .paragraphStyle: paragraphStyle
                ]
                
                let textRect = CGRect(x: margin, y: yPosition, width: contentWidth, height: pageHeight)
                let boundingRect = text.boundingRect(
                    with: CGSize(width: contentWidth, height: CGFloat.greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attributes,
                    context: nil
                )
                
                // Check if we need a new page
                if yPosition + boundingRect.height > pageHeight - margin {
                    context.beginPage()
                    yPosition = margin
                }
                
                text.draw(in: textRect, withAttributes: attributes)
                yPosition += boundingRect.height + extraSpacing
            }
            
            func addSeparator() {
                addText(String(repeating: "-", count: 50))
            }
            
            // TITLE
            addText("REÇU DE PAIEMENT QR EMV", fontSize: 18, isBold: true, extraSpacing: 10)
            addSeparator()
            
            // TRANSACTION STATUS
            addText("Statut: Paiement réussi", fontSize: 12, isBold: true)
            addText("ID Transaction: \(transactionId)")
            addText("Date: \(transactionDate)")
            addText(" ")
            
            // AMOUNT DETAILS
            addText("Montant: \(formatAmount(Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0))", fontSize: 12, isBold: true)
            
            if sendingFee > 0 {
                addText("Frais d'envoi: \(formatAmount(sendingFee))", color: .orange)
            }
            
            if withdrawalFee > 0 {
                addText("Frais de retrait: \(formatAmount(withdrawalFee))", color: .red)
            }
            
            addText("Total débité: \(formatAmount(total))", fontSize: 13, isBold: true, extraSpacing: 10)
            addSeparator()
            
            // SENDER INFO
            addText("ÉMETTEUR", fontSize: 14, isBold: true, extraSpacing: 8)
            addText("Nom: \(senderName)")
            addText("Téléphone: \(senderPhone)", extraSpacing: 10)
            addSeparator()
            
            // RECIPIENT INFO
            addText("MARCHAND", fontSize: 14, isBold: true, extraSpacing: 8)
            addText("Nom: \(merchantName)")
            addText("Type: \(recipientTypeName)")
            addText("Portefeuille: \(merchantWallet)")
            
            if !merchantNumber.isEmpty {
                addText("ID Marchand: \(merchantNumber)")
            }
            
            if !bankCode.isEmpty {
                addText("Banque: \(bankCode)")
            }
            
            if !paymentDetails.isEmpty {
                addText("Détails: \(paymentDetails)", extraSpacing: 10)
            }
            
            addSeparator()
            
            // FOOTER
            addText(" ")
            addText("Ce reçu a été généré automatiquement.", fontSize: 10, color: .gray)
        }
    }
    
    private func generateReceiptText() -> String {
        var feeText = ""
        
        // ✅ Only include fees if they exist
        if sendingFee > 0 {
            feeText += "Frais d'envoi: \(formatAmount(sendingFee))\n"
        }
        
        if withdrawalFee > 0 {
            feeText += "Frais de retrait: \(formatAmount(withdrawalFee))\n"
        }
        
        var merchantDetails = """
        Nom: \(merchantName)
        Type: \(recipientTypeName)
        Portefeuille: \(merchantWallet)
        """
        
        if !merchantNumber.isEmpty { merchantDetails += "\nID Marchand: \(merchantNumber)" }
        if !bankCode.isEmpty { merchantDetails += "\nBanque: \(bankCode)" }
        
        return """
        REÇU DE PAIEMENT QR EMV
        
        Statut: Paiement réussi
        ID Transaction: \(transactionId)
        Date: \(transactionDate)
        
        Montant: \(formatAmount(Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0))
        \(feeText)Total débité: \(formatAmount(total))
        
        ÉMETTEUR
        Nom: \(senderName)
        Téléphone: \(senderPhone)
        
        MARCHAND
        \(merchantDetails)
        
        \(paymentDetails.isEmpty ? "" : "Détails: \(paymentDetails)\n")
        Ce reçu a été généré automatiquement.
        """
    }
}
extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect,
                                            options: [.usesLineFragmentOrigin, .usesFontLeading],
                                            attributes: [.font: font],
                                            context: nil)
        return ceil(boundingBox.height)
    }
}
