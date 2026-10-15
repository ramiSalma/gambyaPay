import SwiftUI
import CoreImage.CIFilterBuiltins

struct MyQRCodeView: View {
    @Environment(\.presentationMode) var presentationMode
    
    private let userDataManager = UserDataManager.shared
    @State private var qrCodeImage: UIImage?
    @State private var showShareSheet = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var qrData: String = ""
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                DiamaPayHeader(title: "My QR Code", headerColor: Color(hex: "174EA6"))

                if isLoading {
                    loadingView
                } else {
                    contentScrollView
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AppBottomBar(onSponsors: {}, onQR: {}, onLimits: {}, onSettings: {})
        }
        .navigationBarHidden(true)
        .onAppear {
            generateCustomerQR()
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = qrCodeImage {
                ShareSheet(items: [image])
            }
        }
    }
    

    // MARK: - Loading
    private var loadingView: some View {
        VStack {
            Spacer()
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blueH))
                    .scaleEffect(1.5)
                
                Text("Génération du code QR...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
    
    // MARK: - Content
    private var contentScrollView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // QR Code Display
                qrCodeCard
                
                // Action Buttons
                actionButtons
                
                // Instructions
                instructionsCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
    }
    
    private var qrCodeCard: some View {
        VStack(spacing: 20) {
            if let qrImage = qrCodeImage {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 280, height: 280)
                    .padding(8)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 80))
                        .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.8))
                    
                    Text("Aucun code QR disponible")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                }
                .frame(width: 280, height: 280)
                .background(Color.white)
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
    }
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            // Save Button
            Button(action: saveQRCode) {
                Text("Enregistrer")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(qrCodeImage == nil ? Color.gray.opacity(0.5) : Color.blueH)
                    .cornerRadius(8)
            }
            .disabled(qrCodeImage == nil)
            
            // Share Button
            Button(action: { showShareSheet = true }) {
                Text("Partager")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(qrCodeImage == nil ? Color.gray.opacity(0.5) : Color.blueH)
                    .cornerRadius(8)
            }
            .disabled(qrCodeImage == nil)
        }
        .padding(.horizontal, 16)
    }
    
    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blueH)
                        .frame(width: 40, height: 40)
                    
                    Text("?")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text("Comment ça marche?")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.blueH)
            }
            
            // Instructions
            Text("1. Montrez ou envoyez ce code QR à la personne qui souhaite vous transférer\n\n2. Elle scanne le code avec son application\n\n3. Elle entre le montant et confirme\n\n4. Vous recevez instantanément l'argent!")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Generate Customer QR
    private func generateCustomerQR() {
        //print("=== GENERATING CUSTOMER QR CODE ===")
        
        isLoading = true
        
        let phoneNumber = userDataManager.getPhoneNumber()
        
        guard !phoneNumber.isEmpty else {
            //print("❌ Phone number not found")
            showError("Numéro de téléphone non trouvé")
            return
        }
        
        //print("Phone: \(phoneNumber)")
        
        // Generate request ID
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyMMdd"
        let datePrefix = dateFormatter.string(from: Date())
        let randomDigits = String(format: "%06d", Int.random(in: 0..<1000000))
        let requestId = datePrefix + randomDigits
        
        // Generate request date
        let fullDateFormatter = DateFormatter()
        fullDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let requestDate = fullDateFormatter.string(from: Date())
        
        var request = GenerateCustomerQRRequest()
        request.requestId = requestId
        request.requestDate = requestDate
        request.customerIdentifier = phoneNumber
        
        //print("Request ID: \(requestId)")
        //print("Request Date: \(requestDate)")
        
        // Call API
        APIClient.shared.getOrGenerateCustomerQR(request: request) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                self.handleQRGenerationResponse(result)
            }
        }
    }
    
    private func handleQRGenerationResponse(_ result: Result<ResponseServiceJson, Error>) {
        //print("=== API RESPONSE ===")
        
        switch result {
        case .success(let response):
            //print("Status: \(response.status ?? "")")
            //print("Code: \(response.respCode ?? "")")
            //print("Message: \(response.message ?? "")")
            
            if response.status == "OK" && response.respCode == "000" {
                handleSuccess(response)
            } else {
                let errorMsg = response.message ?? "Erreur inconnue"
                //print("❌ QR generation failed: \(errorMsg)")
                showError(errorMsg)
            }
            
        case .failure(let error):
            //print("❌ API Failure: \(error.localizedDescription)")
            if let apiError = error as? APIError {
                showError("Erreur: \(apiError.message)")
            } else {
                showError("Erreur réseau: \(error.localizedDescription)")
            }
        }
    }
    
    private func handleSuccess(_ response: ResponseServiceJson) {
        guard let resultObj = response.result else {
            //print("❌ No result data")
            showError("Données QR manquantes")
            return
        }
        
        let qrDataValue = resultObj["qrData"] as? String ?? ""
        let customerName = resultObj["customerName"] as? String ?? ""
        let walletNumber = resultObj["walletNumber"] as? String ?? ""
        
        //print("✅ Extracted Data:")
        //print("  QR Data Length: \(qrDataValue.count)")
        //print("  Customer: \(customerName)")
        //print("  Wallet: \(walletNumber)")
        
        guard !qrDataValue.isEmpty else {
            //print("❌ QR data is empty")
            showError("Données QR vides")
            return
        }
        
        qrData = qrDataValue
        
        // Generate QR code image
        if let qrImage = generateQRCodeBitmap(content: qrDataValue, width: 512, height: 512) {
            qrCodeImage = qrImage
            //print("✅ QR code displayed successfully")
        } else {
            //print("❌ Failed to generate QR image")
            showError("Erreur génération image QR")
        }
    }
    
    private func generateQRCodeBitmap(content: String, width: Int, height: Int) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        guard let data = content.data(using: .utf8) else {
            return nil
        }
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")
        
        guard let outputImage = filter.outputImage else {
            return nil
        }
        
        let scaleX = CGFloat(width) / outputImage.extent.width
        let scaleY = CGFloat(height) / outputImage.extent.height
        let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
        let scaledImage = outputImage.transformed(by: transform)
        
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Actions
    private func saveQRCode() {
        guard let image = qrCodeImage else {
            showError("Aucun code QR à enregistrer")
            return
        }
        
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        alertTitle = "Succès"
        alertMessage = "Code QR enregistré dans la galerie!"
        showAlert = true
        
        //print("✅ QR code saved to gallery")
    }
    
    private func showError(_ message: String) {
        alertTitle = "Erreur"
        alertMessage = message
        showAlert = true
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct MyQRCodeView_Previews: PreviewProvider {
    static var previews: some View {
        MyQRCodeView()
    }
}

struct GenerateCustomerQRRequest: Codable {
    var requestId: String?
    var requestDate: String?
    var customerIdentifier: String?
}
