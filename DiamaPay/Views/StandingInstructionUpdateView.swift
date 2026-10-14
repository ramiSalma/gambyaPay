//
//  StandingInstructionUpdateView.swift
//  DiamaPay
//
//  Created by Bits on 1/10/2025.
//


//
//  StandingInstructionUpdateView.swift
//  DiamaPay
//
//  Created by Assistant on 01/10/2025.
//

import SwiftUI

struct StandingInstructionUpdateView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let instruction: StandingInstruction
    let onSuccess: () -> Void
    
    private let currencies = [
        ("GNF", "324"),
        ("USD", "840"),
        ("EUR", "978"),
        ("XOF", "952"),
        ("XAF", "950")
    ]
    
    private let frequencies = [
        ("Quotidien", "D"),
        ("Hebdomadaire", "W"),
        ("Mensuel", "M"),
        ("Annuel", "Y")
    ]
    
    // MARK: - State Variables
    @State private var amount = ""
    @State private var selectedCurrencyIndex = 0
    @State private var details = ""
    @State private var selectedFrequencyIndex = 2
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var showStartDatePicker = false
    @State private var showEndDatePicker = false
    @State private var pin = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Information"
    
    private let userDataManager = UserDataManager.shared
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                DiamaPayHeader(onBackToHome: {
                    presentationMode.wrappedValue.dismiss()
                })

                if isLoading {
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blueH))
                            .scaleEffect(1.5)
                        
                        Text("Traitement en cours...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            titleCard
                            
                            beneficiaryCard
                            
                            paymentDetailsCard
                            
                            scheduleCard
                            
                            pinCard
                            
                            updateButton
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadInstructionData()
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Title Card
    private var titleCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blueH)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            VStack(spacing: 8) {
                Text("Modifier le Virement")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Rectangle()
                    .fill(.white)
                    .frame(width: 80, height: 3)
            }
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Beneficiary Card
    private var beneficiaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Détails du Bénéficiaire")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.greenH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            // Beneficiary Name (Non-editable)
            HStack {
                Text(instruction.beneficiary ?? "Unknown")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .frame(height: 48)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                    .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Payment Details Card
    private var paymentDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Détails de Paiement")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.greenH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            // Amount
            VStack(alignment: .leading, spacing: 8) {
                Text("Montant")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                FormattedTextField(placeholder: "Entrer le montant", text: $amount)

            }
            
            // Currency
            VStack(alignment: .leading, spacing: 8) {
                Text("Devise")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Menu {
                    ForEach(0..<currencies.count, id: \.self) { index in
                        Button(action: {
                            selectedCurrencyIndex = index
                        }) {
                            Text(currencies[index].0)
                        }
                    }
                } label: {
                    HStack {
                        Text(currencies[selectedCurrencyIndex].0)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 48)
                    .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                    .cornerRadius(8)
                }
            }
            
            // Description
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                
                TextField("Entrer une description", text: $details)
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 12)
                    .frame(height: 48)
                    .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                    .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Schedule Card
    private var scheduleCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Planification")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.greenH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            
            // Start Date
            VStack(alignment: .leading, spacing: 8) {
                Text("Date de début")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Button(action: { showStartDatePicker = true }) {
                    HStack {
                        Text(formatDate(startDate))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "calendar")
                            .foregroundColor(.blueH)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 48)
                    .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                    .cornerRadius(8)
                }
                .sheet(isPresented: $showStartDatePicker) {
                    DatePickerSheetA(selectedDate: $startDate, title: "Date de début")
                }
            }
            
            // End Date
            VStack(alignment: .leading, spacing: 8) {
                Text("Date de fin (optionnel)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Button(action: { showEndDatePicker = true }) {
                    HStack {
                        Text(formatDate(endDate))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "calendar")
                            .foregroundColor(.blueH)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 48)
                    .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                    .cornerRadius(8)
                }
                .sheet(isPresented: $showEndDatePicker) {
                    DatePickerSheetA(selectedDate: $endDate, title: "Date de fin")
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - PIN Card
    private var pinCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Sécurité")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.greenH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Code PIN")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                
                SecureField("Entrer votre PIN", text: $pin)
                    .keyboardType(.numberPad)
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 12)
                    .frame(height: 48)
                    .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                    .cornerRadius(8)
                    .onChange(of: pin) {
                        if pin.count > 4 {
                            pin = String(pin.prefix(4))
                        }
                    }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Update Button
    private var updateButton: some View {
        VStack(spacing: 16) {
            Button(action: validateAndUpdate) {
                Text("Mettre à jour")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 150, height: 48)
                    .background(Color.greenH)
                    .cornerRadius(8)
            }
            .disabled(isLoading)
        }
        .padding(16)
    }
    
    // MARK: - Load Instruction Data
    private func loadInstructionData() {
        amount = instruction.amount ?? ""
        details = instruction.description ?? ""
        
        // Set currency index
        if let currencyCode = instruction.currency {
            if let index = currencies.firstIndex(where: { $0.1 == currencyCode }) {
                selectedCurrencyIndex = index
            }
        }
        
        // Set frequency index
        if let frequencyCode = instruction.frequency {
            if let index = frequencies.firstIndex(where: { $0.1 == frequencyCode }) {
                selectedFrequencyIndex = index
            }
        }
        
        // Parse dates
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        if let startDateStr = instruction.startDate, let date = dateFormatter.date(from: startDateStr) {
            startDate = date
        }
        
        if let endDateStr = instruction.endDate, let date = dateFormatter.date(from: endDateStr) {
            endDate = date
        }
    }
    
    // MARK: - Validate and Update
    private func validateAndUpdate() {
        guard !amount.isEmpty else {
            showErrorAlert("Le montant est requis")
            return
        }
        
        guard !details.isEmpty else {
            showErrorAlert("La description est requise")
            return
        }
        
        guard !pin.isEmpty else {
            showErrorAlert("Le code PIN est requis")
            return
        }
        
        guard startDate < endDate else {
            showErrorAlert("La date de début doit être avant la date de fin")
            return
        }
        
        updateStandingInstruction()
    }
    
    // MARK: - Update Standing Instruction
    private func updateStandingInstruction() {
        isLoading = true
        
        let currencyCode = currencies[selectedCurrencyIndex].1
        let frequencyCode = frequencies[selectedFrequencyIndex].1
        
        let request = StandingInstructionUpdateRequest(
            phoneNumber: userDataManager.getPhoneNumber(),
            id: instruction.reference,
            destination: instruction.destination ?? "",
            amount: amount.cleanCurrencyValue().replacingOccurrences(of: ",", with: "."),
            currency: currencyCode,
            details: details,
            pin: pin,
            frequency: frequencyCode,
            startDate: formatDateForAPI(startDate),
            endDate: formatDateForAPI(endDate),
            requestId: generateRequestId(),
            requestDate: generateRequestDate(),
            entityId: UserDataManager.shared.getUserCode()
        )
        
        APIClient.shared.updateStandingInstruction(request: request) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.respCode == "000" {
                        self.showSuccessAlert("Instruction mise à jour avec succès")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            self.onSuccess()
                        }
                    } else {
                        self.showErrorAlert("Erreur: \(response.message ?? "Échec de la mise à jour")")
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
    
    // MARK: - Helper Methods
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
    
    private func formatDateForAPI(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
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
