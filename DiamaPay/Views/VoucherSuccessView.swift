//
//  VoucherSuccessView.swift
//  DiamaPay
//
//  Created by Bits on 30/9/2025.
//


//
//  VoucherSuccessView.swift
//  DiamaPay
//
//  Created by Bits on 30/9/2025.
//

import SwiftUI
import PDFKit

struct VoucherSuccessView: View {
    let transactionId: String
    let transactionDate: String
    let amount: String
    let recipientName: String
    let recipientPhone: String
    let senderName: String
    let senderPhone: String
    let fee: Double
    let withdrawalFee: Double
    let total: Double
    let currency: String
    let paymentDetails: String
    let voucherCode: String
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
                    
                    Text("Mise à disposition générée")
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
                            DetailRow(label: "Émetteur:", value: senderName)
                            DetailRow(label: "Téléphone:", value: senderPhone)
                        }
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        Group {
                            DetailRow(label: "Destinataire:", value: recipientName.isEmpty ? "Non vérifié" : recipientName)
                            DetailRow(label: "Téléphone:", value: recipientPhone)
                            
                            if !paymentDetails.isEmpty {
                                DetailRow(label: "Détails:", value: paymentDetails)
                            } else {
                                DetailRow(label: "Détails:", value: "Mise à disposition de fonds")
                            }
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // Instructions Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blueH)
                            Text("Instructions")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        
                        Text("Le destinataire peut retirer ces fonds avec le code qu'il reçoit en SMS dans n'importe quel point de service.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blueH.opacity(0.1))
                    .cornerRadius(12)
                    
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
                            .background(.blueH)
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
            .navigationBarTitle("Reçu de mise à disposition", displayMode: .inline)
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
        let fileName = "Recu_Voucher_\(voucherCode).pdf"
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
            kCGPDFContextTitle: "Reçu de Mise à Disposition"
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
            let title = "REÇU DE MISE À DISPOSITION"
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
            drawText("Statut: Mise à disposition générée", at: CGPoint(x: leftMargin, y: yPosition), attributes: contentAttributes, context: context)
            yPosition += 25
            
            drawText("Code Voucher: \(voucherCode)", at: CGPoint(x: leftMargin, y: yPosition), attributes: boldAttributes, context: context)
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
            drawText("ÉMETTEUR", at: CGPoint(x: leftMargin, y: yPosition), attributes: boldAttributes, context: context)
            yPosition += 25
            
            drawText("Nom: \(senderName)", at: CGPoint(x: leftMargin, y: yPosition), attributes: contentAttributes, context: context)
            yPosition += 25
            
            drawText("Téléphone: \(senderPhone)", at: CGPoint(x: leftMargin, y: yPosition), attributes: contentAttributes, context: context)
            yPosition += 35
            
            // Recipient section
            drawText("DESTINATAIRE", at: CGPoint(x: leftMargin, y: yPosition), attributes: boldAttributes, context: context)
            yPosition += 25
            
            let recipientNameText = recipientName.isEmpty ? "Non vérifié" : recipientName
            drawText("Nom: \(recipientNameText)", at: CGPoint(x: leftMargin, y: yPosition), attributes: contentAttributes, context: context)
            yPosition += 25
            
            drawText("Téléphone: \(recipientPhone)", at: CGPoint(x: leftMargin, y: yPosition), attributes: contentAttributes, context: context)
            yPosition += 35
            
            // Payment details
            if !paymentDetails.isEmpty {
                drawText("Détails: \(paymentDetails)", at: CGPoint(x: leftMargin, y: yPosition), attributes: contentAttributes, context: context)
                yPosition += 35
            }
            
            // Instructions
            drawText("INSTRUCTIONS:", at: CGPoint(x: leftMargin, y: yPosition), attributes: boldAttributes, context: context)
            yPosition += 25
            
            drawText("Le destinataire peut retirer ces fonds avec le code", at: CGPoint(x: leftMargin, y: yPosition), attributes: contentAttributes, context: context)
            yPosition += 20
            
            drawText("voucher dans n'importe quel point de service.", at: CGPoint(x: leftMargin, y: yPosition), attributes: contentAttributes, context: context)
            yPosition += 40
            
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
        REÇU DE MISE À DISPOSITION
        
        Statut: Mise à disposition générée
        Code Voucher: \(voucherCode)
        ID Transaction: \(transactionId)
        Date: \(transactionDate)
        
        Montant: \(formatAmount(Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0.0))
        Frais: \(fee > 0 ? formatAmount(fee) : "Gratuit")
        Total débité: \(formatAmount(total))
        
        ÉMETTEUR
        Nom: \(senderName)
        Téléphone: \(senderPhone)
        
        DESTINATAIRE
        Nom: \(recipientName.isEmpty ? "Non vérifié" : recipientName)
        Téléphone: \(recipientPhone)
        
        Détails: \(paymentDetails.isEmpty ? "Mise à disposition de fonds" : paymentDetails)
        
        INSTRUCTIONS:
        Le destinataire peut retirer ces fonds avec le code voucher dans n'importe quel point de service.
        
        Ce reçu a été généré automatiquement.
        """
    }
}

