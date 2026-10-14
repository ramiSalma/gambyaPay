//
//  SendCommentsView.swift
//  DiamaPay
//
//  Created by Bits on 1/10/2025.
//


//
//  SendCommentsView.swift
//  DiamaPay
//
//  Created by Bits on 1/10/2025.
//

import SwiftUI

struct SendCommentsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - State Variables
    @State private var selectedCategory = 0
    @State private var subject: String = ""
    @State private var comment: String = ""
    @State private var email: String = ""
    
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Erreur"
    
    @State private var showConfirmationDialog = false
    @State private var showSuccessDialog = false
    
    private let userDataManager = UserDataManager.shared
    private let maxCommentLength = 500
    
    private let categories = [
        "Interface utilisateur",
        "Fonctionnalités",
        "Performance",
        "Sécurité",
        "Service client",
        "Suggestion d'amélioration",
        "Félicitations",
        "Autre"
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
                        
                        Text("Envoi en cours...")
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
                            
                            // Category Card
                            categoryCard
                            
                            // Subject Card
                            subjectCard
                            
                            // Comment Card
                            commentCard
                            
                            // Email Card (Optional)
                            emailCard
                            
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
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .overlay(confirmationDialogOverlay)
        .sheet(isPresented: $showSuccessDialog) {
            SuccessDialogView(
                title: "Commentaire envoyé",
                message: "Votre commentaire a été envoyé avec succès! Merci pour votre retour.",
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
                CommentConfirmationDialog(
                    category: categories[selectedCategory],
                    subject: subject,
                    isPresented: $showConfirmationDialog,
                    onConfirm: {
                        showConfirmationDialog = false
                        submitComment()
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
                Text("Commentaires & Suggestions")
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
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blueH)
                    .font(.system(size: 18))
                
                Text("Nous valorisons vos retours")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Text("Partagez vos commentaires, suggestions ou félicitations pour nous aider à améliorer nos services.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color.blueH.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Category Card
    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Catégorie")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.greenH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            Menu {
                ForEach(0..<categories.count, id: \.self) { index in
                    Button(action: {
                        selectedCategory = index
                    }) {
                        HStack {
                            Text(categories[index])
                            if selectedCategory == index {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(categories[selectedCategory])
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
    
    // MARK: - Subject Card
    private var subjectCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Sujet")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.greenH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            TextField("Entrer le sujet", text: $subject)
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
    
    // MARK: - Comment Card
    private var commentCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Commentaire")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.greenH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                TextEditor(text: $comment)
                    .font(.system(size: 12, weight: .medium))
                    .frame(height: 120)
                    .padding(8)
                    .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                    .cornerRadius(8)
                    .onChange(of: comment) {
                        if comment.count > maxCommentLength {
                            comment = String(comment.prefix(maxCommentLength))
                        }
                    }
                
                HStack {
                    Spacer()
                    Text("\(comment.count)/\(maxCommentLength) caractères")
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
    
    // MARK: - Email Card
    private var emailCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Email (optionnel)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.greenH)
                
                Rectangle()
                    .fill(Color.blueH)
                    .frame(width: 60, height: 2)
            }
            
            TextField("Entrer votre email", text: $email)
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
            Text("Envoyer")
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
        let percentage = Double(comment.count) / Double(maxCommentLength)
        if percentage > 0.9 {
            return .red
        } else if percentage > 0.7 {
            return .orange
        } else {
            return .secondary
        }
    }
    
    // MARK: - Helper Methods
    private func validateInputs() -> Bool {
        if subject.trimmingCharacters(in: .whitespaces).isEmpty {
            showErrorAlert("Veuillez entrer un sujet")
            return false
        }
        
        if comment.trimmingCharacters(in: .whitespaces).isEmpty {
            showErrorAlert("Veuillez entrer votre commentaire")
            return false
        }
        
        if comment.trimmingCharacters(in: .whitespaces).count < 10 {
            showErrorAlert("Le commentaire doit contenir au moins 10 caractères")
            return false
        }
        
        if !email.isEmpty && !isValidEmail(email) {
            showErrorAlert("Format d'email invalide")
            return false
        }
        
        return true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func submitComment() {
        isLoading = true
        
        let request = CommentRequest(
            userName: userDataManager.getUserName(),
            userPhone: userDataManager.getPhoneNumber(),
            category: categories[selectedCategory],
            subject: subject.trimmingCharacters(in: .whitespaces),
            comment: comment.trimmingCharacters(in: .whitespaces),
            email: email.isEmpty ? nil : email.trimmingCharacters(in: .whitespaces)
        )
        
        APIClient.shared.sendComment(request: request) { result in
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
    
    private func handleApiError(_ error: APIError) {
        let message: String
        switch error.respCode {
        case "400":
            message = "Données invalides. Veuillez vérifier vos informations."
        case "401":
            message = "Session expirée. Veuillez vous reconnecter."
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

// MARK: - Confirmation Dialog
struct CommentConfirmationDialog: View {
    let category: String
    let subject: String
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
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blueH)
                    
                    Text("Confirmer l'envoi")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                // Details
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Catégorie:")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(category)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Sujet:")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(subject)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    }
                }
                .padding(16)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                Text("Êtes-vous sûr de vouloir envoyer ce commentaire?")
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
                        Text("Envoyer")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.greenH)
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

// MARK: - Preview
struct SendCommentsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SendCommentsView()
        }
    }
}
