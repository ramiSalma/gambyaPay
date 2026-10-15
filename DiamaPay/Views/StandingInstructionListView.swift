//
//  StandingInstructionListView.swift
//  DiamaPay
//
//  Created by Bits on 1/10/2025.
//


//
//  StandingInstructionListView.swift
//  DiamaPay
//
//  Created by Assistant on 01/10/2025.
//

import SwiftUI

struct StandingInstructionListView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var instructions: [StandingInstruction] = []
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Information"
    @State private var showCreateSheet = false
    @State private var showUpdateSheet = false
    @State private var selectedInstruction: StandingInstruction? = nil
    @State private var showDeleteDialog = false
    @State private var instructionToDelete: StandingInstruction? = nil
    
    private let userDataManager = UserDataManager.shared
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                DiamaPayHeader(title: "Standing Instructions", headerColor: Color(hex: "174EA6"))

                // Title Card
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                
                // Content
                if isLoading {
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blueH))
                            .scaleEffect(1.5)
                        
                        Text("Chargement...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else if instructions.isEmpty {
                    emptyStateView
                } else {
                    instructionsList
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AppBottomBar(onSponsors: {}, onQR: {}, onLimits: {}, onSettings: {})
        }
        .navigationBarHidden(true)
        .onAppear {
            loadStandingInstructions()
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showCreateSheet) {
            NavigationView {
                StandingInstructionCreateView(onSuccess: {
                    showCreateSheet = false
                    loadStandingInstructions()
                })
            }
        }
        .sheet(item: $selectedInstruction) { instruction in
            NavigationView {
                StandingInstructionUpdateView(
                    instruction: instruction,
                    onSuccess: {
                        selectedInstruction = nil
                        loadStandingInstructions()
                    }
                )
            }
        }
        .overlay(deleteConfirmationDialog)
    }
    

    
    // MARK: - Title Card
    private var titleCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blueH)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            VStack(spacing: 6) {  // Reduced from 8
                Text("Virements Permanents")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Rectangle()
                    .fill(.white)
                    .frame(width: 80, height: 3)
            }
            .padding(.vertical, 12)  // Reduced from 16
        }
        .fixedSize(horizontal: false, vertical: true)  // Add this line
        .padding(.horizontal, 16)
        .padding(.top, 8)  // Reduced from 20
    }
    
    // MARK: - Instructions List
    private var instructionsList: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(instructions) { instruction in
                        StandingInstructionRow(
                            instruction: instruction,
                            onUpdate: {
                                selectedInstruction = instruction
                            },
                            onDelete: {
                                instructionToDelete = instruction
                                showDeleteDialog = true
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 80)
            }
            
            // FAB - Create Button
            Button(action: {
                showCreateSheet = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Créer")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.blueH)
                .cornerRadius(28)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            .padding(.trailing, 16)
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Vous n'avez aucun virement permanent")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                showCreateSheet = true
            }) {
                Text("Créer un virement")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blueH)
                    .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Delete Confirmation Dialog
    private var deleteConfirmationDialog: some View {
        Group {
            if showDeleteDialog, let instruction = instructionToDelete {
                DeleteConfirmationDialog(
                    instruction: instruction,
                    isPresented: $showDeleteDialog,
                    onConfirm: { pin in
                        showDeleteDialog = false
                        deleteInstruction(instruction, pin: pin)
                    },
                    onCancel: {
                        showDeleteDialog = false
                        instructionToDelete = nil
                    }
                )
            }
        }
    }
    
    // MARK: - Load Instructions
    private func loadStandingInstructions() {
        isLoading = true
        
        let phoneNumber = userDataManager.getPhoneNumber()
        guard !phoneNumber.isEmpty else {
            isLoading = false
            showErrorAlert("Numéro de téléphone non disponible")
            return
        }
        
        let request = RequestStandingInstructionList(
            phoneNumber: phoneNumber,
            requestId: generateRequestId(),
            requestDate: generateRequestDate(),
            entityId: UserDataManager.shared.getUserCode()
        )
        
        APIClient.shared.listStandingInstructions(request: request) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.respCode == "000", let resultList = response.result {
                        self.parseInstructions(from: resultList)
                    } else {
                        self.instructions = []
                    }
                case .failure(let error):
                    if let apiError = error as? APIError {
                        self.showErrorAlert("Erreur: \(apiError.message)")
                    } else {
                        self.showErrorAlert("Erreur réseau: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // MARK: - Parse Instructions
    private func parseInstructions(from resultList: [Any]) {
        var parsedInstructions: [StandingInstruction] = []
        
        for item in resultList {
            guard let dict = item as? [String: Any] else { continue }
            
            let instruction = StandingInstruction(
                reference: dict["reference"] as? String ?? "",
                destination: dict["destination"] as? String,
                beneficiary: dict["beneficiary"] as? String ?? "Unknown",
                description: dict["description"] as? String ?? "",
                amount: String(describing: dict["amount"] ?? "0"),
                currency: dict["currency"] as? String ?? "324",
                destBank: dict["destBank"] as? String,
                trxType: dict["trxType"] as? String,
                destBankCode: dict["destBankCode"] as? String,
                frequency: dict["frequency"] as? String ?? "D",
                frequencyNum: dict["frequencyNum"] as? String,
                startDate: convertDateFormat(dict["startDate"] as? String ?? ""),
                endDate: convertDateFormat(dict["endDate"] as? String ?? ""),
                nextDate: dict["nextDate"] as? String
            )
            
            if !instruction.reference.isEmpty {
                parsedInstructions.append(instruction)
            }
        }
        
        self.instructions = parsedInstructions
    }
    
    // MARK: - Delete Instruction
    private func deleteInstruction(_ instruction: StandingInstruction, pin: String) {
        isLoading = true
        
        let request = RequestStandingInstructionDelete(
            bank: "00100",
            destBank: "",
            entityId: UserDataManager.shared.getUserCode(),
            id: instruction.reference,
            phoneNumber: userDataManager.getPhoneNumber(),
            pin: pin,
            requestDate: generateRequestDate(),
            requestId: generateRequestId()
        )
        
        APIClient.shared.deleteStandingInstruction(request: request) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.respCode == "000" {
                        self.showSuccessAlert("Virement permanent supprimé avec succès")
                        self.loadStandingInstructions()
                    } else {
                        self.showErrorAlert("Erreur: \(response.message ?? "Échec de la suppression")")
                    }
                case .failure(let error):
                    if let apiError = error as? APIError {
                        self.showErrorAlert("Erreur: \(apiError.message)")
                    } else {
                        self.showErrorAlert("Erreur réseau: \(error.localizedDescription)")
                    }
                }
                
                self.instructionToDelete = nil
            }
        }
    }
    
    // MARK: - Helper Methods
    private func convertDateFormat(_ dateString: String) -> String {
        guard !dateString.isEmpty else { return "" }
        
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "MM-dd-yyyy"
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "yyyy-MM-dd"
        outputFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        }
        
        return dateString
    }
    
    private func generateRequestId() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyMMdd"
        let datePrefix = dateFormatter.string(from: Date())
        let randomDigits = String(format: "%06d", Int.random(in: 0...999999))
        return datePrefix + randomDigits
    }
    
    private func generateRequestDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: Date())
    }
    
    private func showErrorAlert(_ message: String) {
        alertTitle = "Erreur"
        alertMessage = message
        showAlert = true
    }
    
    private func showSuccessAlert(_ message: String) {
        alertTitle = "Succès"
        alertMessage = message
        showAlert = true
    }
}

// MARK: - Standing Instruction Row
struct StandingInstructionRow: View {
    let instruction: StandingInstruction
    let onUpdate: () -> Void
    let onDelete: () -> Void
    
    @State private var showMenu = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(instruction.beneficiary ?? "Unknown")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(formatAmount(instruction.amount ?? "0") + " " + getCurrencyDisplay(instruction.currency ?? "324"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.blueH)
                }
                
                Spacer()
                
                Button(action: {
                    showMenu = true
                }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.gray)
                        .rotationEffect(.degrees(90))
                        .padding(8)
                }
            }
            .padding(16)
            
            Divider()
                .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 8) {
                DetailRowSmall(label: "Fréquence:", value: getFrequencyDisplay(instruction.frequency ?? "D"))
                DetailRowSmall(label: "Prochaine date:", value: instruction.nextDate ?? "N/A")
                if let description = instruction.description, !description.isEmpty {
                    DetailRowSmall(label: "Description:", value: description)
                }
            }
            .padding(16)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .confirmationDialog("Options", isPresented: $showMenu, titleVisibility: .hidden) {
            Button("Modifier") {
                onUpdate()
            }
            
            Button("Supprimer", role: .destructive) {
                onDelete()
            }
            
            Button("Annuler", role: .cancel) { }
        }
    }
    
    private func formatAmount(_ amount: String) -> String {
        guard let doubleAmount = Double(amount.replacingOccurrences(of: ",", with: ".")) else {
            return amount
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: NSNumber(value: doubleAmount)) ?? amount
    }
    
    private func getCurrencyDisplay(_ code: String) -> String {
        switch code {
        case "324": return "GNF"
        case "840": return "USD"
        case "978": return "EUR"
        default: return code
        }
    }
    
    private func getFrequencyDisplay(_ code: String) -> String {
        switch code {
        case "D": return "Quotidien"
        case "W": return "Hebdomadaire"
        case "M": return "Mensuel"
        case "Y": return "Annuel"
        default: return code
        }
    }
}

struct DetailRowSmall: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Delete Confirmation Dialog
struct DeleteConfirmationDialog: View {
    let instruction: StandingInstruction
    @Binding var isPresented: Bool
    let onConfirm: (String) -> Void
    let onCancel: () -> Void
    
    @State private var pin = ""
    @State private var showError = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }
            
            VStack(spacing: 0) {
                // Header
                Text("Confirmer la suppression")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                
                // Message
                Text("Entrez votre code PIN pour supprimer ce virement permanent")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                
                // PIN Input
                SecureField("Code PIN", text: $pin)
                    .keyboardType(.numberPad)
                    .font(.system(size: 16, weight: .medium))
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .onChange(of: pin) {
                        if pin.count > 4 {
                            pin = String(pin.prefix(4))
                        }
                    }
                
                if showError {
                    Text("Veuillez entrer votre PIN")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                        .padding(.top, 4)
                }
                
                // Buttons
                HStack(spacing: 12) {
                    Button(action: onCancel) {
                        Text("Annuler")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.blueH)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.blueH.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        if pin.isEmpty {
                            showError = true
                        } else {
                            showError = false
                            onConfirm(pin)
                        }
                    }) {
                        Text("Confirmer")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 20)
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 32)
        }
    }
}

struct StandingInstructionListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StandingInstructionListView()
        }
    }
}
