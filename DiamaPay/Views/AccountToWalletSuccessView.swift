//
//  AccountToWalletSuccessView.swift
//  DiamaPay
//
//  Created by Bits on 30/9/2025.
//


//
//  AccountToWalletSuccessView.swift
//  DiamaPay
//
//  Created by Bits on 30/9/2025.
//

import SwiftUI
import PDFKit

struct AccountToWalletSuccessView: View {
    let transactionId: String
    let transactionDate: String
    let amount: String
    let sourceAccountNumber: String
    let sourceAccountHolder: String
    let sourceBankName: String
    let recipientName: String
    let recipientWallet: String
    let recipientPhone: String
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
                    
                    Text("Transfert vers portefeuille réussi")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
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
                        
                        // Source Account Section
                        Text("COMPTE SOURCE")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        Group {
                            DetailRow(label: "Titulaire:", value: sourceAccountHolder)
                            DetailRow(label: "Numéro de compte:", value: sourceAccountNumber)
                            DetailRow(label: "Banque:", value: sourceBankName)
                        }
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        // Recipient Wallet Section
                        Text("PORTEFEUILLE DESTINATAIRE")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        Group {
                            DetailRow(label: "Nom:", value: recipientName)
                            DetailRow(label: "Portefeuille:", value: recipientWallet)
                            DetailRow(label: "Téléphone:", value: recipientPhone)
                            
                            if !paymentDetails.isEmpty {
                                DetailRow(label: "Détails:", value: paymentDetails)
                            } else {
                                DetailRow(label: "Détails:", value: "Transfert vers portefeuille")
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
                            generateAndSharePDF()
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
        formatter.locale = Locale(identifier: "en_GM")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return (formatter.string(from: NSNumber(value: amount)) ?? "0") + " " + currency
    }
    
    private func generateAndSharePDF() {
        let pdfData = createPDF()
        savePDFAndShare(data: pdfData)
    }
    
    private func createPDF() -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "DIAMACASH",
            kCGPDFContextAuthor: "DIAMACASH",
            kCGPDFContextTitle: "Reçu de Transfert vers Portefeuille"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { (context) in
            context.beginPage()
            
            let titleAttributes = [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 22),
                NSAttributedString.Key.foregroundColor: UIColor.black
            ]
            
            let bodyAttributes = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),
                NSAttributedString.Key.foregroundColor: UIColor.black
            ]
            
            let boldAttributes = [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14),
                NSAttributedString.Key.foregroundColor: UIColor.black
            ]
            
            var yPosition: CGFloat = 80
            let margin: CGFloat = 50
            let lineSpacing: CGFloat = 25
            
            // Title
            let title = "REÇU DE TRANSFERT VERS PORTEFEUILLE"
            let titleSize = title.size(withAttributes: titleAttributes)
            let titleRect = CGRect(x: (pageWidth - titleSize.width) / 2, y: yPosition, width: titleSize.width, height: titleSize.height)
            title.draw(in: titleRect, withAttributes: titleAttributes)
            
            yPosition += titleSize.height + 20
            
            // Draw line
            context.cgContext.setStrokeColor(UIColor.black.cgColor)
            context.cgContext.setLineWidth(2)
            context.cgContext.move(to: CGPoint(x: margin, y: yPosition))
            context.cgContext.addLine(to: CGPoint(x: pageWidth - margin, y: yPosition))
            context.cgContext.strokePath()
            
            yPosition += 30
            
            // Transaction Status
            drawText("Statut: Transfert vers portefeuille réussi", at: CGPoint(x: margin, y: yPosition), attributes: bodyAttributes, context: context)
            yPosition += lineSpacing
            
            drawText("ID Transaction: \(transactionId)", at: CGPoint(x: margin, y: yPosition), attributes: bodyAttributes, context: context)
            yPosition += lineSpacing
            
            drawText("Date: \(transactionDate)", at: CGPoint(x: margin, y: yPosition), attributes: bodyAttributes, context: context)
            yPosition += lineSpacing
            
            drawText("Montant: \(formatAmount(Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0.0))", at: CGPoint(x: margin, y: yPosition), attributes: bodyAttributes, context: context)
            yPosition += lineSpacing
            
            drawText("Frais: \(fee > 0 ? formatAmount(fee) : "Gratuit")", at: CGPoint(x: margin, y: yPosition), attributes: bodyAttributes, context: context)
            yPosition += lineSpacing + 10
            
            drawText("Total débité: \(formatAmount(total))", at: CGPoint(x: margin, y: yPosition), attributes: boldAttributes, context: context)
            yPosition += lineSpacing

            // Separator
            context.cgContext.move(to: CGPoint(x: margin, y: yPosition))
            context.cgContext.addLine(to: CGPoint(x: pageWidth - margin, y: yPosition))
            context.cgContext.strokePath()
            yPosition += 20
            
            // Source Account Section
            drawText("COMPTE SOURCE", at: CGPoint(x: margin, y: yPosition), attributes: boldAttributes, context: context)
            yPosition += lineSpacing
            
            drawText("Titulaire: \(sourceAccountHolder)", at: CGPoint(x: margin, y: yPosition), attributes: bodyAttributes, context: context)
            yPosition += lineSpacing
            
            drawText("Numéro de compte: \(sourceAccountNumber)", at: CGPoint(x: margin, y: yPosition), attributes: bodyAttributes, context: context)
            yPosition += lineSpacing
            
            drawText("Banque: \(sourceBankName)", at: CGPoint(x: margin, y: yPosition), attributes: bodyAttributes, context: context)
            yPosition += lineSpacing + 20
            
            // Recipient Wallet Section
            drawText("PORTEFEUILLE DESTINATAIRE", at: CGPoint(x: margin, y: yPosition), attributes: boldAttributes, context: context)
            yPosition += lineSpacing
            
            drawText("Nom: \(recipientName)", at: CGPoint(x: margin, y: yPosition), attributes: bodyAttributes, context: context)
            yPosition += lineSpacing
            
            drawText("Portefeuille: \(recipientWallet)", at: CGPoint(x: margin, y: yPosition), attributes: bodyAttributes, context: context)
            yPosition += lineSpacing
            
            drawText("Téléphone: \(recipientPhone)", at: CGPoint(x: margin, y: yPosition), attributes: bodyAttributes, context: context)
            yPosition += lineSpacing
            
            if !paymentDetails.isEmpty {
                drawText("Détails du paiement: \(paymentDetails)", at: CGPoint(x: margin, y: yPosition), attributes: bodyAttributes, context: context)
                yPosition += lineSpacing
            }
            
            yPosition += 30
            
            // Footer separator
            context.cgContext.move(to: CGPoint(x: margin, y: yPosition))
            context.cgContext.addLine(to: CGPoint(x: pageWidth - margin, y: yPosition))
            context.cgContext.strokePath()
            yPosition += 20
            
            let footerAttributes = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10),
                NSAttributedString.Key.foregroundColor: UIColor.gray
            ]
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy 'à' HH:mm"
            let footer = "Ce reçu a été généré automatiquement le \(dateFormatter.string(from: Date()))"
            drawText(footer, at: CGPoint(x: margin, y: yPosition), attributes: footerAttributes, context: context)
        }
        
        return data
    }
    
    private func drawText(_ text: String, at point: CGPoint, attributes: [NSAttributedString.Key: Any], context: UIGraphicsPDFRendererContext) {
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        attributedString.draw(at: point)
    }
    
    private func savePDFAndShare(data: Data) {
        let fileName = "Recu_Transfert_Portefeuille_\(transactionId).pdf"
        
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let fileURL = documentDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            
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
                    activityItems: [fileURL],
                    applicationActivities: nil
                )
                
                // For iPad
                if let popoverController = activityViewController.popoverPresentationController {
                    popoverController.sourceView = topVC.view
                    popoverController.sourceRect = CGRect(x: topVC.view.bounds.midX,
                                                          y: topVC.view.bounds.midY,
                                                          width: 0, height: 0)
                    popoverController.permittedArrowDirections = []
                }
                
                topVC.present(activityViewController, animated: true)
            }
        } catch {
            //print("Error saving PDF: \(error.localizedDescription)")
        }
    }
}

struct AccountToWalletSuccessView_Previews: PreviewProvider {
    static var previews: some View {
        AccountToWalletSuccessView(
            transactionId: "123456789",
            transactionDate: "30/09/2025 14:30:00",
            amount: "50000",
            sourceAccountNumber: "GN012345678901234",
            sourceAccountHolder: "Jean Dupont",
            sourceBankName: "Banque Centrale",
            recipientName: "Marie Martin",
            recipientWallet: "WLT123456",
            recipientPhone: "622123456",
            withdrawalFee: 100,
            fee: 500,
            total: 50500,
            currency: "GMD",
            paymentDetails: "Test transfer",
            onClose: {}
        )
    }
}
