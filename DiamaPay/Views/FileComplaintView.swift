//
//  FileComplaintView.swift
//  DiamaPay
//
//  Created by Bits on 1/10/2025.
//


//
//  FileComplaintView.swift
//  DiamaPay
//
//  Created by Bits on 1/10/2025.
//

import SwiftUI

struct FileComplaintView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - State Variables
    @State private var selectedComplaintType = 0
    @State private var selectedPriority = 0
    @State private var selectedContactMethod = 0
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var incidentDate: String = ""
    @State private var transactionRef: String = ""
    @State private var alternateContact: String = ""
    
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Erreur"
    
    @State private var showConfirmationDialog = false
    @State private var showSuccessDialog = false
    
    private let userDataManager = UserDataManager.shared
    private let maxDescriptionLength = 1000
    
    private let complaintTypes = [
        "Transaction échouée",
        "Débit non autorisé",
        "Problème de sécurité",
        "Service client",
        "Application défaillante",
        "Frais incorrects",
        "Problème de compte",
        "Autre"
    ]
    
    private let priorities = [
        "🔴 Urgent - Perte financière",
        "🟠 Élevé - Service indisponible",
        "🟡 Moyen - Problème fonctionnel",
        "🟢 Faible - Amélioration"
    ]
    
    private let contactMethods = [
        "SMS (Numéro enregistré)",
        "Email (alternatif)",
        "Ne pas me contacter"
    ]
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                DiamaPayHeader()

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
                            // Title Card
                            titleCard
                            
                            // Instruction
                            instructionCard
                            
                            // Complaint Type Card
                            complaintTypeCard
                            
                            // Priority Card
                            priorityCard
                            
                            // Title Card
                            titleInputCard
                            
                            // Description Card
                            descriptionCard
                            
                            // Incident Date Card
                            incidentDateCard
                            
                            // Transaction Reference Card
                            transactionRefCard
                            
                            // Contact Method Card
                            contactMethodCard
                            
                            // Alternate Contact Card (conditional)
                            if selectedContactMethod == 1 {
                                alternateContactCard
                            }
                            
                            // Submit Button
                            submitButton
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setDefaultDate()
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .overlay(confirmationDialogOverlay)
        .sheet(isPresented: $showSuccessDialog) {
            ComplaintSuccessDialogView(
                complaintType: complaintTypes[selectedComplaintType],
                priority: extractPriorityLevel(priorities[selectedPriority]),
                title: title,
                expectedResolution: getExpectedResolutionTime(extractPriorityLevel(priorities[selectedPriority])),
                onClose: {
                    showSuccessDialog = false
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private var confirmationDialogOverlay: some View {
        Group {
            if showConfirmationDialog {
                ComplaintConfirmationDialog(
                    complaintType: complaintTypes[selectedComplaintType],
                    priority: priorities[selectedPriority],
                    title: title,
                    expectedResolution: getExpectedResolutionTime(extractPriorityLevel(priorities[selectedPriority])),
                    isPresented: $showConfirmationDialog,
                    onConfirm: {
                        showConfirmationDialog = false
                        submitComplaint()
                    },
                    onCancel: {
                        showConfirmationDialog = false
                    }
                )
            }
        }
    }
    
    
    // MARK: - Title Card
    private var titleCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blueH)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            VStack(spacing: 8) {
                Text("Déposer une Plainte")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Rectangle()
                    .fill(.white)
                    .frame(width: 80, height: 3)
            }
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Instruction Card
    private var instructionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 18))
                
                Text("Signaler un problème")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Text("Veuillez fournir autant de détails que possible pour nous aider à résoudre votre problème rapidement.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color.orange.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Complaint Type Card
    private var complaintTypeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Type de Plainte")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.greenH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            Menu {
                ForEach(0..<complaintTypes.count, id: \.self) { index in
                    Button(action: {
                        selectedComplaintType = index
                    }) {
                        HStack {
                            Text(complaintTypes[index])
                            if selectedComplaintType == index {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(complaintTypes[selectedComplaintType])
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
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
    
    // MARK: - Priority Card
    private var priorityCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Priorité")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.greenH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            Menu {
                ForEach(0..<priorities.count, id: \.self) { index in
                    Button(action: {
                        selectedPriority = index
                    }) {
                        HStack {
                            Text(priorities[index])
                            if selectedPriority == index {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(priorities[selectedPriority])
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
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
    
    // MARK: - Title Input Card
    private var titleInputCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Titre")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.greenH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            TextField("Entrer le titre", text: $title)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                .cornerRadius(8)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Description Card
    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Description")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.greenH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                TextEditor(text: $description)
                    .font(.system(size: 12, weight: .medium))
                    .frame(height: 120)
                    .padding(8)
                    .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                    .cornerRadius(8)
                    .onChange(of: description) {
                        if description.count > maxDescriptionLength {
                            description = String(description.prefix(maxDescriptionLength))
                        }
                    }
                
                HStack {
                    Spacer()
                    Text("\(description.count)/\(maxDescriptionLength) caractères")
                        .font(.system(size: 11))
                        .foregroundColor(characterCountColor)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Incident Date Card
    private var incidentDateCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Date de l'incident")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.greenH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            TextField("JJ/MM/AAAA", text: $incidentDate)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                .cornerRadius(8)
                .disabled(true)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Transaction Reference Card
    private var transactionRefCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Référence Transaction (optionnel)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.greenH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            TextField("Entrer la référence", text: $transactionRef)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                .cornerRadius(8)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Contact Method Card
    private var contactMethodCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Méthode de Contact")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.greenH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            Menu {
                ForEach(0..<contactMethods.count, id: \.self) { index in
                    Button(action: {
                        selectedContactMethod = index
                    }) {
                        HStack {
                            Text(contactMethods[index])
                            if selectedContactMethod == index {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(contactMethods[selectedContactMethod])
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
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
    
    // MARK: - Alternate Contact Card
    private var alternateContactCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Email Alternatif")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.greenH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            TextField("Entrer votre email", text: $alternateContact)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                .cornerRadius(8)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Submit Button
    private var submitButton: some View {
        Button(action: {
            if validateInputs() {
                showConfirmationDialog = true
            }
        }) {
            Text("Soumettre")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 150, height: 48)
                .background(Color.greenH)
                .cornerRadius(8)
        }
        .disabled(isLoading)
        .padding(.bottom, 20)
    }
    
    // MARK: - Computed Properties
    private var characterCountColor: Color {
        let percentage = Double(description.count) / Double(maxDescriptionLength)
        if percentage > 0.9 {
            return .red
        } else if percentage > 0.7 {
            return .orange
        } else {
            return .secondary
        }
    }
    
    // MARK: - Helper Methods
    private func setDefaultDate() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        incidentDate = dateFormatter.string(from: Date())
    }
    
    private func validateInputs() -> Bool {
        if title.trimmingCharacters(in: .whitespaces).isEmpty {
            showErrorAlert("Veuillez entrer un titre")
            return false
        }
        
        if title.trimmingCharacters(in: .whitespaces).count < 5 {
            showErrorAlert("Le titre doit contenir au moins 5 caractères")
            return false
        }
        
        if description.trimmingCharacters(in: .whitespaces).isEmpty {
            showErrorAlert("Veuillez décrire votre plainte")
            return false
        }
        
        if description.trimmingCharacters(in: .whitespaces).count < 20 {
            showErrorAlert("La description doit contenir au moins 20 caractères")
            return false
        }
        
        if incidentDate.trimmingCharacters(in: .whitespaces).isEmpty {
            showErrorAlert("Veuillez entrer la date de l'incident")
            return false
        }
        
        if selectedContactMethod == 1 && !alternateContact.isEmpty {
            if !isValidEmail(alternateContact) {
                showErrorAlert("Format d'email invalide")
                return false
            }
        }
        
        return true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func submitComplaint() {
        isLoading = true
        
        let request = ComplaintRequest(
            userPhone: userDataManager.getPhoneNumber(),
            userName: userDataManager.getUserName(),
            complaintType: complaintTypes[selectedComplaintType],
            priority: extractPriorityLevel(priorities[selectedPriority]),
            title: title.trimmingCharacters(in: .whitespaces),
            description: description.trimmingCharacters(in: .whitespaces),
            incidentDate: incidentDate,
            transactionRef: transactionRef.isEmpty ? nil : transactionRef.trimmingCharacters(in: .whitespaces),
            contactMethod: contactMethods[selectedContactMethod],
            alternateContact: alternateContact.isEmpty ? nil : alternateContact.trimmingCharacters(in: .whitespaces)
        )
        
        APIClient.shared.sendComplaint(request: request) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success:
                    self.showSuccessDialog = true
                case .failure(let error):
                    if let apiError = error as? APIError {
                        self.handleApiError(apiError)
                    } else {
                        self.showErrorAlert("Erreur réseau: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func extractPriorityLevel(_ priority: String) -> String {
        if priority.contains("Urgent") { return "URGENT" }
        if priority.contains("Élevé") { return "ÉLEVÉ" }
        if priority.contains("Moyen") { return "MOYEN" }
        if priority.contains("Faible") { return "FAIBLE" }
        return "MOYEN"
    }
    
    private func getExpectedResolutionTime(_ priority: String) -> String {
        switch priority {
        case "URGENT": return "24-48 heures"
        case "ÉLEVÉ": return "2-3 jours ouvrables"
        case "MOYEN": return "5-7 jours ouvrables"
        case "FAIBLE": return "7-14 jours ouvrables"
        default: return "5-7 jours ouvrables"
        }
    }
    
    private func handleApiError(_ error: APIError) {
        let message: String
        switch error.respCode {
        case "400":
            message = "Données invalides. Veuillez vérifier vos informations."
        case "401":
            message = "Session expirée. Veuillez vous reconnecter."
        case "429":
            message = "Vous avez déposé trop de plaintes récemment. Veuillez attendre."
        case "500", "502", "503":
            message = "Erreur du serveur. Veuillez réessayer plus tard."
        default:
            message = error.message
        }
        showErrorAlert(message)
    }
    
    private func showErrorAlert(_ message: String) {
        alertTitle = "Erreur"
        alertMessage = message
        showAlert = true
    }
}

// MARK: - Complaint Confirmation Dialog
struct ComplaintConfirmationDialog: View {
    let complaintType: String
    let priority: String
    let title: String
    let expectedResolution: String
    @Binding var isPresented: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }
            
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("Confirmer le dépôt de plainte")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                }
                
                // Details
                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(label: "Type:", value: complaintType)
                    Divider()
                    DetailRow(label: "Priorité:", value: priority.replacingOccurrences(of: #"^[🔴🟠🟡🟢]\s*"#, with: "", options: .regularExpression))
                    Divider()
                    DetailRow(label: "Titre:", value: title)
                    Divider()
                    DetailRow(label: "Résolution estimée:", value: expectedResolution)
                }
                .padding(16)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                Text("Êtes-vous sûr de vouloir déposer cette plainte?")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Buttons
                HStack(spacing: 12) {
                    Button(action: onCancel) {
                        Text("Annuler")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blueH)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.blueH.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Button(action: onConfirm) {
                        Text("Déposer")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.orange)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(radius: 20)
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Complaint Success Dialog
struct ComplaintSuccessDialogView: View {
    let complaintType: String
    let priority: String
    let title: String
    let expectedResolution: String
    let onClose: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                        .padding(.top, 20)
                    
                    Text("Plainte déposée")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        DetailRow(label: "Type:", value: complaintType)
                        Divider()
                        DetailRow(label: "Priorité:", value: priority)
                        Divider()
                        DetailRow(label: "Titre:", value: title)
                        Divider()
                        DetailRow(label: "Temps de résolution estimé:", value: expectedResolution)
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    Text("Vous recevrez une confirmation et des mises à jour selon votre méthode de contact préférée.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: onClose) {
                        Text("Fermer")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.blueH)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .navigationBarItems(trailing: Button("Fermer", action: onClose))
            .navigationBarTitle("Confirmation", displayMode: .inline)
        }
    }
}

// MARK: - Success Dialog (for Comments)
struct SuccessDialogView: View {
    let title: String
    let message: String
    let onClose: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Spacer()
                
                Button(action: onClose) {
                    Text("Fermer")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blueH)
                        .cornerRadius(8)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .navigationBarItems(trailing: Button("Fermer", action: onClose))
            .navigationBarTitle("Succès", displayMode: .inline)
        }
    }
}

// MARK: - Preview
struct FileComplaintView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FileComplaintView()
        }
    }
}
