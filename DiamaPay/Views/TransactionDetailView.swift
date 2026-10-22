//
//  TransactionDetailView.swift
//  DiamaPay
//
//  Created by Bits on 13/11/2025.
//

import SwiftUI
import PDFKit

struct TransactionDetailView: View {
    @ObservedObject private var localization = AppLanguageStore.shared
    @Environment(\.dismiss) private var dismiss
    let transaction: Transaction
    @State private var itemsToShare: [Any]?

    var body: some View {
        ZStack {
            Color(hex: "F4F7FC")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                DiamaPayHeader(title: AppStrings.transactionDetails, headerColor: Color(hex: "174EA6"))
                ScrollView {
                    VStack(spacing: 18) {
                        transactionInfoCard
                        
                        Button(action: {
                            generatePDF()
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "square.and.arrow.up")
                                Text(AppStrings.shareReceipt)
                            }
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "174EA6"), Color(hex: "0788B9")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Color(hex: "174EA6").opacity(0.22), radius: 10, x: 0, y: 5)
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
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AppBottomBar(onSponsors: {}, onQR: {}, onLimits: {}, onSettings: {})
        }
        .navigationBarHidden(true)
    }
    
    private var transactionInfoCard: some View {
        VStack(spacing: 14) {
            summaryCard

            VStack(alignment: .leading, spacing: 4) {
                Text(AppStrings.transactionInformation2)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.1)
                    .foregroundColor(Color(hex: "174EA6"))
                    .padding(.bottom, 6)

                detailRow(label: AppStrings.reference, value: transaction.transactionReference ?? AppStrings.nA)
                detailRow(label: AppStrings.type, value: transaction.displayTitle)
                detailRow(label: AppStrings.details, value: transaction.details ?? AppStrings.noAdditionalDetails)
                detailRow(label: AppStrings.openingBalance, value: transaction.openingBalance ?? AppStrings.nA)
                detailRow(label: AppStrings.closingBalance, value: transaction.closingBalance ?? AppStrings.nA)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "DCE7F7"), lineWidth: 1))
            .shadow(color: Color(hex: "174EA6").opacity(0.06), radius: 12, x: 0, y: 5)
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
    }

    private var summaryCard: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [Color(hex: "123B7A"), Color(hex: "1768B2"), Color(hex: "0788B9")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 180, height: 180)
                .offset(x: 58, y: -90)

            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 110, height: 110)
                .offset(x: -110, y: 115)

            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    Image(systemName: transaction.isDebit ? "arrow.up.right" : "arrow.down.left")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.16))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(transaction.displayTitle)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text(transaction.displayDate)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.76))
                    }

                    Spacer(minLength: 0)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(transaction.isDebit ? AppStrings.moneySent : AppStrings.moneyReceived)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.78))
                    Text(transaction.amount)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.75)
                        .lineLimit(1)
                }

                HStack {
                    Label(transaction.status ?? AppStrings.unknown, systemImage: statusIcon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(0.16))
                        .clipShape(Capsule())

                    Spacer()

                    Text(AppStrings.refValue(String(describing: transaction.transactionReference ?? AppStrings.nA)))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.82))
                        .lineLimit(1)
                }
            }
            .padding(20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.25), lineWidth: 1))
        .shadow(color: Color(hex: "174EA6").opacity(0.24), radius: 16, x: 0, y: 8)
    }

    private var statusIcon: String {
        let status = (transaction.status ?? "").lowercased()
        if status.contains("approv") || status.contains("success") || status == "ok" || status == "000" || status == "completed" {
            return "checkmark.circle.fill"
        }
        if status.contains("pending") || status.contains("processing") {
            return "clock.fill"
        }
        if status.contains("fail") || status.contains("reject") || status.contains("declin") || status.contains("error") {
            return "xmark.circle.fill"
        }
        return "info.circle.fill"
    }
    
    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "496589"))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "172B4D"))
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 11)
    }

    private func generatePDF() {
        //print("🔵 Starting PDF generation")
        
        let pdfMetaData = [
            kCGPDFContextCreator: AppStrings.brand,
            kCGPDFContextAuthor: "DIAMACASH App",
            kCGPDFContextTitle: AppStrings.transactionReceipt
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
            
            AppStrings.transactionReceipt2.draw(at: CGPoint(x: leftMargin, y: yOffset), withAttributes: [
                .font: titleFont,
                .foregroundColor: textColor
            ])
            yOffset += 40
            
            let lines = [
                AppStrings.referenceValue(String(describing: transaction.transactionReference ?? AppStrings.nA)),
                AppStrings.dateValue(String(describing: transaction.displayDate)),
                AppStrings.typeValue(String(describing: transaction.displayTitle)),
                AppStrings.amountValue(String(describing: transaction.amount)),
                AppStrings.statusValue(String(describing: transaction.status ?? AppStrings.unknown)),
                AppStrings.detailsValue(String(describing: transaction.details ?? AppStrings.nA)),
                AppStrings.openingBalanceValue(String(describing: transaction.openingBalance ?? AppStrings.nA)),
                AppStrings.closingBalanceValue(String(describing: transaction.closingBalance ?? AppStrings.nA))
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
