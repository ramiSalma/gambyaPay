//
//  AccountTransferSuccessView.swift
//  DiamaPay
//
//  Created by Bits on 30/9/2025.
//

import SwiftUI
import PDFKit

struct AccountTransferSuccessView: View {
    let transactionId: String
    let transactionDate: String
    let amount: String
    let accountName: String
    let accountNumber: String
    let bankName: String
    let senderName: String
    let senderWallet: String
    let senderPhone: String
    let withdrawalFee: Double
    let fee: Double
    let total: Double
    let currency: String
    let paymentDetails: String
    let onClose: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Success Icon
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                        .padding(.top, 20)
                    
                    Text("Transfert vers compte réussi")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    // Transaction Details Card
                    VStack(alignment: .leading, spacing: 16) {
                        Group {
                            DetailRow(label: "ID Transaction:", value: transactionId)
                            DetailRow(label: "Date:", value: transactionDate)
                            DetailRow(label: "Montant:", value: formatAmount(Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0.0))
                            if withdrawalFee > 0 {
                                DetailRow(label: "Frais d'envoi:", value: formatAmount(withdrawalFee))
                            }
                            
                            DetailRow(label: "Frais:", value: fee > 0 ? formatAmount(fee) : "Gratuit")
                            DetailRow(label: "Total débité:", value: formatAmount(total))
                        }
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        Group {
                            DetailRow(label: "Expéditeur:", value: senderName)
                            DetailRow(label: "Portefeuille:", value: senderWallet)
                            DetailRow(label: "Téléphone:", value: senderPhone)
                        }
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        Group {
                            DetailRow(label: "Compte:", value: accountName)
                            DetailRow(label: "N° Compte:", value: accountNumber)
                            DetailRow(label: "Banque:", value: bankName)
                            
                            if !paymentDetails.isEmpty {
                                DetailRow(label: "Détails:", value: paymentDetails)
                            } else {
                                DetailRow(label: "Détails:", value: "Transfert vers compte bancaire")
                            }
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            shareReceipt()
                        }) {
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
            .navigationBarTitle("Reçu de transfert", displayMode: .inline)
        }
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "fr_FR")
        return (formatter.string(from: NSNumber(value: amount)) ?? "0") + " " + currency
    }
    
    private func shareReceipt() {
        // Generate PDF
        let pdfData = generatePDF()
        
        // Save to temporary directory
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "Recu_Transfert_Compte_\(transactionId).pdf"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try pdfData.write(to: fileURL)
            
            // Add delay and find topmost view controller
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootVC = windowScene.windows.first?.rootViewController else {
                    return
                }
                
                // Find the topmost presented view controller
                var topVC = rootVC
                while let presented = topVC.presentedViewController {
                    topVC = presented
                }
                
                let activityViewController = UIActivityViewController(
                    activityItems: [fileURL, generateReceiptText()],
                    applicationActivities: nil
                )
                
                // For iPad
                if let popover = activityViewController.popoverPresentationController {
                    popover.sourceView = topVC.view
                    popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                
                topVC.present(activityViewController, animated: true)
            }
        } catch {
            //print("Error saving PDF: \(error)")
        }
    }
    
    private func generatePDF() -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "DIAMACASH",
            kCGPDFContextAuthor: senderName,
            kCGPDFContextTitle: "Reçu de Transfert vers Compte"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = 60
            let leftMargin: CGFloat = 50
            let rightMargin: CGFloat = 545
            
            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            let title = "REÇU DE TRANSFERT VERS COMPTE"
            title.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: titleAttributes)
            yPosition += 40
            
            // Draw line
            context.cgContext.setStrokeColor(UIColor.black.cgColor)
            context.cgContext.setLineWidth(2)
            context.cgContext.move(to: CGPoint(x: leftMargin, y: yPosition))
            context.cgContext.addLine(to: CGPoint(x: rightMargin, y: yPosition))
            context.cgContext.strokePath()
            yPosition += 30
            
            let contentAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.black
            ]
            
            let boldAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor.black
            ]
            
            // Transaction details
            drawText("Statut: Transfert vers compte réussi", at: CGPoint(x: leftMargin, y: yPosition), attributes: contentAttributes, context: context)
            yPosition += 25
            
            drawText("ID Transaction: \(transactionId)", at: CGPoint(x: leftMargin, y: yPosition), attributes: contentAttributes, context: context)
            yPosition += 25
            
            drawText("Date: \(transactionDate)", at: CGPoint(x: leftMargin, y: yPosition), attributes: contentAttributes, context: context)
            yPosition += 25
            
            drawText("Montant: \(formatAmount(Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0.0))", at: CGPoint(x: leftMargin, y: yPosition), attributes: contentAttributes, context: context)
            yPosition += 25
            
            
            drawText("Frais: \(fee > 0 ? formatAmount(fee) : "Gratuit")", at: CGPoint(x: leftMargin, y: yPosition), attributes: contentAttributes, context: context)
            yPosition += 25
            
            drawText("Total débité: \(formatAmount(total))", at: CGPoint(x: leftMargin, y: yPosition), attributes: boldAttributes, context: context)
            yPosition += 35
            
            // Separator
            context.cgContext.setLineWidth(1)
            context.cgContext.move(to: CGPoint(x: leftMargin, y: yPosition))
            context.cgContext.addLine(to: CGPoint(x: rightMargin, y: yPosition))
            context.cgContext.strokePath()
            yPosition += 25
            
            // Sender section
            drawText("EXPÉDITEUR", at: CGPoint(x: leftMargin, y: yPosition), attributes: boldAttributes, context: context)
            yPosition += 25
            
            drawText("Nom: \(senderName)", at: CGPoint(x: leftMargin, y: yPosition), attributes: contentAttributes, context: context)
            yPosition += 25
            
            drawText("Portefeuille: \(senderWallet)", at: CGPoint(x: leftMargin, y: yPosition), attributes: contentAttributes, context: context)
            yPosition += 25
            
            drawText("Téléphone: \(senderPhone)", at: CGPoint(x: leftMargin, y: yPosition), attributes: contentAttributes, context: context)
            yPosition += 35
            
            // Recipient section
            drawText("COMPTE DESTINATAIRE", at: CGPoint(x: leftMargin, y: yPosition), attributes: boldAttributes, context: context)
            yPosition += 25
            
            drawText("Nom du compte: \(accountName)", at: CGPoint(x: leftMargin, y: yPosition), attributes: contentAttributes, context: context)
            yPosition += 25
            
            drawText("Numéro de compte: \(accountNumber)", at: CGPoint(x: leftMargin, y: yPosition), attributes: contentAttributes, context: context)
            yPosition += 25
            
            drawText("Banque: \(bankName)", at: CGPoint(x: leftMargin, y: yPosition), attributes: contentAttributes, context: context)
            yPosition += 35
            
            // Payment details
            if !paymentDetails.isEmpty {
                drawText("Détails: \(paymentDetails)", at: CGPoint(x: leftMargin, y: yPosition), attributes: contentAttributes, context: context)
                yPosition += 35
            }
            
            // Footer separator
            context.cgContext.move(to: CGPoint(x: leftMargin, y: yPosition))
            context.cgContext.addLine(to: CGPoint(x: rightMargin, y: yPosition))
            context.cgContext.strokePath()
            yPosition += 25
            
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.gray
            ]
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy 'à' HH:mm"
            let footerText = "Ce reçu a été généré automatiquement le \(dateFormatter.string(from: Date()))"
            drawText(footerText, at: CGPoint(x: leftMargin, y: yPosition), attributes: footerAttributes, context: context)
        }
        
        return data
    }
    
    private func drawText(_ text: String, at point: CGPoint, attributes: [NSAttributedString.Key: Any], context: UIGraphicsPDFRendererContext) {
        text.draw(at: point, withAttributes: attributes)
    }
    
    private func generateReceiptText() -> String {
        return """
        REÇU DE TRANSFERT VERS COMPTE BANCAIRE
        
        Statut: Transfert vers compte réussi
        ID Transaction: \(transactionId)
        Date: \(transactionDate)
        
        Montant: \(formatAmount(Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0.0))
        Frais: \(fee > 0 ? formatAmount(fee) : "Gratuit")
        
        Total débité: \(formatAmount(total))
        
        EXPÉDITEUR
        Nom: \(senderName)
        Portefeuille: \(senderWallet)
        Téléphone: \(senderPhone)
        
        DESTINATAIRE
        Nom du compte: \(accountName)
        Numéro de compte: \(accountNumber)
        Banque: \(bankName)
        
        Détails: \(paymentDetails.isEmpty ? "Transfert vers compte bancaire" : paymentDetails)
        
        Ce reçu a été généré automatiquement.
        """
    }
}
