//
//  TransactionDetailView.swift
//  DiamaPay
//
//  Created by Bits on 13/11/2025.
//

import SwiftUI
import PDFKit

struct TransactionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let transaction: Transaction
    @State private var itemsToShare: [Any]?

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                DiamaPayHeader()
                titleCard
                
                ScrollView {
                    VStack(spacing: 20) {
                        transactionInfoCard
                        
                        Button(action: {
                            generatePDF()
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Partager en PDF")
                            }
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blueH)
                            .cornerRadius(10)
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .sheet(item: Binding(
            get: { itemsToShare != nil ? ShareItem(items: itemsToShare!) : nil },
            set: { itemsToShare = $0?.items }
        )) { shareItem in
            ActivityViewController(activityItems: shareItem.items)
        }
        .navigationBarHidden(true)
    }
    
    private var titleCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blueH)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            VStack(spacing: 8) {
                Text("Détails de la transaction")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Rectangle()
                    .fill(.white)
                    .frame(width: 80, height: 3)
            }
            .padding(.vertical, 8)
        }
        .frame(height: 80)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    private var transactionInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            detailRow(label: "Référence", value: transaction.transactionReference ?? "N/A")
            detailRow(label: "Date", value: transaction.transactionDate ?? "N/A")
            detailRow(label: "Type", value: transaction.title)
            detailRow(
                label: "Montant",
                value: transaction.amount,
                color: transaction.isDebit ? .red : .greenH
            )
            detailRow(
                label: "Statut",
                value: transaction.status ?? "Inconnu",
                color: (transaction.status ?? "") == "Approuvé" ? .greenH : .red
            )
            detailRow(label: "Détails", value: transaction.details ?? "Aucun détail")
            detailRow(label: "Solde initial", value: transaction.openingBalance ?? "N/A")
            detailRow(label: "Solde final", value: transaction.closingBalance ?? "N/A")
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
    
    private func detailRow(label: String, value: String, color: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func generatePDF() {
        //print("🔵 Starting PDF generation")
        
        let pdfMetaData = [
            kCGPDFContextCreator: "DIAMACASH",
            kCGPDFContextAuthor: "DIAMACASH App",
            kCGPDFContextTitle: "Reçu de transaction"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth: CGFloat = 8.5 * 72.0
        let pageHeight: CGFloat = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        //print("🔵 Creating PDF data")
        let data = renderer.pdfData { context in
            context.beginPage()
            
            let titleFont = UIFont.boldSystemFont(ofSize: 22)
            let textFont = UIFont.systemFont(ofSize: 14)
            let textColor = UIColor.black
            
            var yOffset: CGFloat = 40
            let leftMargin: CGFloat = 40
            
            let title = "Reçu de Transaction"
            title.draw(at: CGPoint(x: leftMargin, y: yOffset), withAttributes: [
                .font: titleFont,
                .foregroundColor: textColor
            ])
            yOffset += 40
            
            let lines = [
                "Référence: \(transaction.transactionReference ?? "N/A")",
                "Date: \(transaction.transactionDate ?? "N/A")",
                "Type: \(transaction.title)",
                "Montant: \(transaction.amount)",
                "Statut: \(transaction.status ?? "Inconnu")",
                "Détails: \(transaction.details ?? "N/A")",
                "Solde initial: \(transaction.openingBalance ?? "N/A")",
                "Solde final: \(transaction.closingBalance ?? "N/A")"
            ]
            
            //print("🔵 Drawing \(lines.count) lines")
            for line in lines {
                line.draw(at: CGPoint(x: leftMargin, y: yOffset), withAttributes: [
                    .font: textFont,
                    .foregroundColor: textColor
                ])
                yOffset += 24
            }
        }
        
        //print("🔵 PDF data size: \(data.count) bytes")
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Transaction-\(transaction.transactionReference ?? UUID().uuidString).pdf")
        
        //print("🔵 Attempting to write to: \(url.path)")
        
        do {
            try data.write(to: url)
            //print("✅ PDF written successfully")
            //print("🔵 File exists: \(FileManager.default.fileExists(atPath: url.path))")
            
            if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) {
                //print("🔵 File size: \(attributes[.size] ?? 0) bytes")
            }
            
            //print("🔵 Setting itemsToShare with URL: \(url)")
            self.itemsToShare = [url]
            //print("🔵 itemsToShare is now: \(String(describing: self.itemsToShare))")
            
        } catch {
            //print("❌ Error writing PDF: \(error.localizedDescription)")
        }
    }
}

// Helper struct to make the items identifiable
struct ShareItem: Identifiable {
    let id = UUID()
    let items: [Any]
}

struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        //print("🔵 Creating UIActivityViewController with \(activityItems.count) items")
        for (index, item) in activityItems.enumerated() {
            //print("🔵 Item \(index): \(item)")
        }
        
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        
        // For iPad support
        if let popover = controller.popoverPresentationController {
            popover.sourceView = UIView()
            popover.permittedArrowDirections = []
        }
        
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        //print("🔵 updateUIViewController called")
    }
}
