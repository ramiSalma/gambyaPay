//
//  RegistrationFlowView.swift
//  DiamaPay
//
//  Created by Bits on 25/9/2025.
//

import SwiftUI

struct RegistrationFlowView: View {
    @State private var currentStep = 1
    @StateObject private var registrationData = RegistrationData()
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss
    @State private var showImagePicker = false
    @State private var pickerType: String = ""
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .camera
    @State private var showingActionSheet = false
    
    // API data states
    @State private var nationalities: [Nationality] = []
    @State private var secretQuestions: [SecretQuestion] = []
    @State private var isLoadingNationalities = false
    @State private var isLoadingSecretQuestions = false
    
    // Terms and Conditions tracking
    @State private var expandedTermsSections: Set<String> = []
    
    let totalSteps = 6
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerView
                
                ScrollView {
                    VStack(spacing: 20) {
                        stepContentView
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 30)
                }
                
                navigationButtonsView
            }
            .navigationBarHidden(true)
            .background(Color(.systemGroupedBackground))
        }
        .alert("Erreur", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text("Sélectionner la source"),
                message: Text("Choisissez comment ajouter la photo"),
                buttons: [
                    .default(Text("📷 Appareil photo")) {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            imagePickerSourceType = .camera
                            showImagePicker = true
                        } else {
                            imagePickerSourceType = .photoLibrary
                            showImagePicker = true
                        }
                    },
                    .default(Text("📁 Bibliothèque de photos")) {
                        imagePickerSourceType = .photoLibrary
                        showImagePicker = true
                    },
                    .cancel(Text("Annuler"))
                ]
            )
        }
        .onAppear {
            fetchNationalities()
            fetchSecretQuestions()
        }
    }
    
    // MARK: - Header View with Step Indicator
    private var headerView: some View {
        VStack(spacing: 20) {
            // "Étape" text centered with back arrow on the left
            ZStack {
                // Back arrow on the left
                HStack {
                    Button(action: {
                        if currentStep > 1 {
                            currentStep -= 1
                        } else {
                            dismiss()
                        }
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                }
                
                // Centered text
                Text("Étape \(currentStep) sur \(totalSteps)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // Step Indicator
            HStack(spacing: 8) {
                ForEach(1...totalSteps, id: \.self) { step in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(step <= currentStep ? Color.blueH : Color.white)
                            .stroke(Color.white)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Text("\(step)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(step <= currentStep ? .white : .gray)
                            )
                        
                        if step < totalSteps {
                            Rectangle()
                                .fill(step < currentStep ? Color.green : Color.white.opacity(0.5))
                                .frame(height: 2)
                                .frame(maxWidth: 60)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Color.greenH)
    }
    
    // MARK: - Step Content View
    @ViewBuilder
    private var stepContentView: some View {
        switch currentStep {
        case 1: step1PersonalInfoView
        case 2: step2PinSetupView
        case 3: step3DocumentScanView
        case 4: step4TermsAndConditionsView
        case 5: step5OtpVerificationView
        case 6: step6SuccessView
        default: EmptyView()
        }
    }
    
    // MARK: - Step 1: Personal Info
    private var step1PersonalInfoView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Saisissez vos informations personnelles")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
            
            sectionHeader("Informations de base")
            CustomTextField(title: "Prénom*", text: $registrationData.firstName)
            CustomTextField(title: "Nom de Famille*", text: $registrationData.lastName)
            CustomTextField(title: "Numéro de téléphone*", text: $registrationData.phoneNumber, icon: "phone.fill", keyboardType: .phonePad)
            CustomTextField(title: "Email", text: $registrationData.email, icon: "envelope", keyboardType: .emailAddress)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Date de Naissance*")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blueH)
                        .frame(width: 20)
                    
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { registrationData.birthDate ?? Date() },
                            set: {
                                registrationData.birthDate = $0
                                let formatter = DateFormatter()
                                formatter.dateFormat = "yyyy-MM-dd"
                                registrationData.dateOfBirth = formatter.string(from: $0)
                            }
                        ),
                        in: ...Calendar.current.date(byAdding: .year, value: -18, to: Date())!,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Genre*")
                    .font(.system(size: 16, weight: .medium))
                HStack(spacing: 20) {
                    GenderButton(title: "Masculin", isSelected: registrationData.gender == "M") {
                        registrationData.gender = "M"
                    }
                    GenderButton(title: "Féminin", isSelected: registrationData.gender == "F") {
                        registrationData.gender = "F"
                    }
                }
            }
            
            sectionHeader("Identification")
            
            // Nationality Picker with Search
            SearchableNationalityPicker(
                nationalities: nationalities,
                isLoading: isLoadingNationalities,
                selectedNationality: $registrationData.nationalityDisplay,
                onSelect: { nationality in
                    registrationData.nationality = nationality.code
                    registrationData.nationalityDisplay = nationality.wording
                }
            )
            
            CustomTextField(title: "Adresse résidentielle*", text: $registrationData.address, icon: "location.circle")
            
            sectionHeader("Sécurité")
            
            // Secret Question Picker with API
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Question secrète*")
                        .font(.system(size: 16, weight: .medium))
                    
                    if isLoadingSecretQuestions {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
                
                Menu {
                    if secretQuestions.isEmpty {
                        Button("Chargement...") { }
                            .disabled(true)
                    } else {
                        ForEach(secretQuestions, id: \.id) { question in
                            Button(question.question) {
                                registrationData.secretQ = question.id
                                registrationData.secretQDisplay = question.question
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.blueH)
                            .frame(width: 20)
                        
                        Text(registrationData.secretQDisplay.isEmpty ? "Sélectionner une question" : registrationData.secretQDisplay)
                            .foregroundColor(registrationData.secretQDisplay.isEmpty ? .gray : .primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .disabled(isLoadingSecretQuestions || secretQuestions.isEmpty)
            }
            
            CustomTextField(title: "Votre réponse*", text: $registrationData.answer)
            
            sectionHeader("Personne à contacter (optionnel)")
            CustomTextField(title: "Nom de la personne à contacter", text: $registrationData.nkinName)
            CustomTextField(title: "Téléphone de la personne à contacter", text: $registrationData.nkinPhone, icon: "phone.fill", keyboardType: .phonePad)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 10)
    }

    // MARK: - Step 2: PIN Setup
    private var step2PinSetupView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Créez votre code PIN")
                .font(.system(size: 24, weight: .semibold))
            
            Text("Ce code PIN sera utilisé pour sécuriser votre compte et confirmer vos transactions.")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            
            VStack(spacing: 16) {
                SecureField("Saisissez votre code PIN à 4 chiffres", text: $registrationData.pin)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .onChange(of: registrationData.pin) {
                        if registrationData.pin.count > 4 {
                            registrationData.pin = String(registrationData.pin.prefix(4))
                        }
                    }
                
                SecureField("Confirmez votre code PIN", text: $registrationData.confirmPin)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .onChange(of: registrationData.confirmPin) {
                        if registrationData.confirmPin.count > 4 {
                            registrationData.confirmPin = String(registrationData.confirmPin.prefix(4))
                        }
                    }
                
                if !registrationData.pin.isEmpty || !registrationData.confirmPin.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: registrationData.pin.count == 4 ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(registrationData.pin.count == 4 ? .green : .red)
                            Text("PIN doit contenir 4 chiffres")
                                .font(.caption)
                        }
                        
                        if registrationData.pin.count == 4 {
                            HStack {
                                Image(systemName: isWeakPin(registrationData.pin) ? "xmark.circle.fill" : "checkmark.circle.fill")
                                    .foregroundColor(isWeakPin(registrationData.pin) ? .red : .green)
                                Text(isWeakPin(registrationData.pin)
                                     ? "Ce PIN n'est pas sécurisé, veuillez en choisir un autre"
                                     : "PIN suffisamment sécurisé")
                                    .font(.caption)
                                    .foregroundColor(isWeakPin(registrationData.pin) ? .red : .primary)
                            }
                        }
                        
                        if !registrationData.confirmPin.isEmpty {
                            HStack {
                                Image(systemName: registrationData.pin == registrationData.confirmPin ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(registrationData.pin == registrationData.confirmPin ? .green : .red)
                                Text("Les PINs doivent correspondre")
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Step 3: Document Scan View
    private var step3DocumentScanView: some View {
        VStack(spacing: 25) {
            Text("Numérisez vos documents d'identification")
                .font(.system(size: 20, weight: .semibold))
            
            identificationCard(
                title: "1. Photo personnelle",
                description: "Prenez une photo de votre visage clair et net.",
                buttonText: registrationData.selfieBase64.isEmpty ? "Prendre une photo" : "✓ Photo capturée - Refaire",
                systemIcon: "person.circle.fill",
                isCompleted: !registrationData.selfieBase64.isEmpty,
                isEnabled: true
            ) {
                pickerType = "selfie"
                showSourceSelection()
            }
            
            if !registrationData.selfieBase64.isEmpty {
                identificationCard(
                    title: "2. Recto de la carte d'identité",
                    description: "Assurez-vous que toutes les informations sont visibles.",
                    buttonText: registrationData.idFrontBase64.isEmpty ? "Prendre une photo" : "✓ Recto capturé - Refaire",
                    systemIcon: "creditcard.fill",
                    isCompleted: !registrationData.idFrontBase64.isEmpty,
                    isEnabled: true
                ) {
                    pickerType = "idFront"
                    showSourceSelection()
                }
            }
            
            if !registrationData.selfieBase64.isEmpty && !registrationData.idFrontBase64.isEmpty {
                identificationCard(
                    title: "3. Verso de la carte d'identité",
                    description: "Assurez-vous que toutes les informations sont visibles.",
                    buttonText: registrationData.idBackBase64.isEmpty ? "Prendre une photo" : "✓ Verso capturé - Refaire",
                    systemIcon: "creditcard.and.123",
                    isCompleted: !registrationData.idBackBase64.isEmpty,
                    isEnabled: true
                ) {
                    pickerType = "idBack"
                    showSourceSelection()
                }
            }
            
            let completedDocs = [registrationData.selfieBase64, registrationData.idFrontBase64, registrationData.idBackBase64].filter { !$0.isEmpty }.count
            
            HStack {
                Text("Documents complétés: \(completedDocs)/3")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                ProgressView(value: Double(completedDocs), total: 3.0)
                    .frame(width: 100)
            }
            .padding(.horizontal)
            
            if completedDocs == 3 {
                Text("Tous les documents sont capturés - Vous pouvez continuer")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.top, 10)
            }
        }
        .padding(.horizontal, 20)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: imagePickerSourceType) { image in
                handleImageSelection(image)
            }
        }
    }
    
    // MARK: - Step 4: Terms and Conditions (COMPLETE VERSION)
    private var step4TermsAndConditionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Conditions Générales d'Utilisation")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            Text("DIAMACASH - DIAMA BANK SA")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.blueH)
            
            Text("Veuillez lire et accepter toutes les conditions pour continuer")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            
            // Complete terms content in scrollview
            ScrollView {
                LazyVStack(spacing: 12) {
                    // Definitions Section
                    termsSection(
                        icon: "book.fill",
                        title: "Définitions",
                        id: "definitions"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            termsParagraph("Pour les besoins du présent contrat, il convient d'entendre par :")
                            
                            termsDefinitionItem("Banque", "La DIAMA BANK SA.")
                            termsDefinitionItem("Contrat", "Désigne le présent contrat d'adhésion au service DIAMACASH, ses Conditions Générales de fonctionnement, ses Conditions Particulières ainsi que tout document annexe et avenant, qui constitue un tout indivisible.")
                            termsDefinitionItem("Application mobile", "Une application mobile est un logiciel applicatif développé pour un appareil électronique mobile, tel qu'un assistant personnel, un téléphone portable, un smartphone…")
                            termsDefinitionItem("Wallet", "Constitue un moyen de paiement permettant à son détenteur de stocker de façon sécurisée dans un portefeuille numérique, de la monnaie électronique en vue d'effectuer des paiements, d'émettre ou de recevoir des transferts d'argent ainsi que de faire du cash in et du cash out.")
                            termsDefinitionItem("Etablissement", "Désigne tout établissement bancaire ou les établissements de paiement.")
                            termsDefinitionItem("Cash-In", "Il s'agit d'une opération de dépôt d'espèce au niveau du Wallet.")
                            termsDefinitionItem("Cash-Out", "Il s'agit d'une opération de retrait d'espèce à partir du Wallet, auprès d'un distributeur agréé par la DIAMA BANK SA.")
                            termsDefinitionItem("Compte de rattachement", "Désigne le compte ouvert dans les livres de la Banque tel que précisé dans le Bulletin d'Adhésion et sur lequel est rattaché le Wallet.")
                            termsDefinitionItem("Détenteur du Wallet", "Peut-être le titulaire du compte ou toute autre personne nommément désignée dans le présent contrat.")
                            termsDefinitionItem("DIAMACASH", "Désigne l'application de paiement mobile pour les clients à titre privé.")
                            termsDefinitionItem("DAB/GAB", "Appareils de distribution automatique de billets de Banque.")
                            termsDefinitionItem("TPE", "Terminal de Paiement Electronique.")
                        }
                    }
                    
                    // Object Section
                    termsSection(
                        icon: "target",
                        title: "Objet",
                        id: "object"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            termsParagraph("Le Wallet DIAMACASH est un moyen de paiement électronique sécurisé, pouvant être lié au compte bancaire du client ouvert dans les livres de la DIAMA BANK SA, qui permet à son titulaire d'effectuer en temps réel différents services de paiement et de transfert d'argent et ce, via l'application mobile DIAMACASH.")
                            termsParagraph("Cette application est téléchargeable à partir de Google Play et Apple Store.")
                        }
                    }
                    
                    // Features Section
                    termsSection(
                        icon: "star.fill",
                        title: "Fonctionnalités du service",
                        id: "features"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            termsParagraph("Les fonctionnalités disponibles au niveau de l'application DIAMACASH sont :")
                            
                            termsDefinitionItem("La souscription", "Le client peut initier directement son inscription sur l'application DIAMACASH en renseignant les formulaires associés ou se rendre soit chez un agent agréé, soit en agence pour se faire assister pour son inscription.")
                            termsDefinitionItem("La connexion", "Le client se connecte à son compte DIAMACASH à l'aide de son numéro de téléphone et de son code secret. Lors de la toute première connexion, il lui sera demandé de saisir un code de confirmation qu'il recevra par sms pour des raisons de sécurité.")
                            termsDefinitionItem("La liaison de son compte bancaire", "Le client qui a un compte bancaire ouvert dans les livres de la DIAMA BANK SA peut se rendre en agence pour demander la liaison de son compte et ainsi effectuer les opérations de transfert gratuitement entre son compte DIAMACASH et son compte bancaire.")
                            termsDefinitionItem("Le déplafonnement du wallet", "Par défaut, le compte DIAMACASH du client est limité à un solde maximum de 5.000.000 GNF lors de l'ouverture de son compte à distance. Il peut cependant se rendre en agence ou chez un distributeur agréé pour signer la convention de contrat et demander le déplafonnement de son compte DIAMACASH.")
                            termsDefinitionItem("Le Chargement du Wallet (Cash-In)", "Le détenteur du Wallet peut bénéficier de deux canaux de chargement : Chargement au niveau des distributeurs en faisant un versement espèces, ou Chargement via son compte bancaire DIAMA BANK SA lié à son wallet.")
                            termsDefinitionItem("Retrait d'argent (Cash-Out)", "Le client peut se rendre chez n'importe quels distributeurs pour effectuer un retrait sur son compte DIAMACASH.")
                            termsDefinitionItem("Transfert vers un autre compte DIAMACASH", "Le client peut à tout moment effectuer des transferts d'argent à un autre wallet client dans la limite de son solde et de ces autorisations.")
                            termsDefinitionItem("Transfert vers ma banque", "Le client peut à tout moment effectuer des transferts d'argent vers son compte bancaire DIAMA BANK SA qui a été au préalable lié à son wallet.")
                            termsDefinitionItem("Transfert de ma banque", "Le client peut à tout moment effectuer des transferts d'argent depuis son compte bancaire DIAMA BANK SA qui a été au préalable lié à son wallet.")
                            termsDefinitionItem("Mise à disposition", "Le client peut à tout moment effectuer des transferts d'argent à une personne n'ayant pas de compte DIAMACASH.")
                            termsDefinitionItem("Parrainage", "Le client peut à tout moment effectuer le parrainage d'un autre compte DIAMACASH.")
                            termsDefinitionItem("Virement permanent", "Le client peut à tout moment initier des virements permanents vers un autre compte DIAMACASH.")
                            termsDefinitionItem("Paiement chez le commerçant", "Le Client peut payer ses achats à partir de son Wallet DIAMACASH, auprès des commerçants accepteurs détenant un Wallet DIAMACASH PRO.")
                        }
                    }
                    
                    // Article 1
                    termsArticle(number: 1, title: "Conditions d'inscription au service", id: "article1") {
                        VStack(alignment: .leading, spacing: 12) {
                            termsParagraph("Le Service est réservé à la clientèle des particuliers, personnes physiques majeures titulaires disposant :")
                            termsBulletPoint("D'un smartphone compatible avec Play Store ou Apple Store")
                            termsBulletPoint("D'un numéro mobile guinéen en leur nom")
                            termsParagraph("L'utilisation de DIAMACASH se fait en Guinée comme à l'étranger.")
                        }
                    }
                    
                    // Article 2
                    termsArticle(number: 2, title: "Accès au service", id: "article2") {
                        VStack(alignment: .leading, spacing: 12) {
                            termsParagraph("L'accès au service est subordonné au respect par l'Utilisateur des dispositions de ce contrat.")
                            
                            Text("Moyens techniques :")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.primary)
                                .padding(.top, 8)
                            
                            termsParagraph("L'accès au Service se fait via l'utilisation d'Internet au moyen d'un terminal mobile. L'Utilisateur s'assure de disposer à minima :")
                            termsBulletPoint("D'un smartphone, de sa mise en service et de sa maintenance")
                            termsBulletPoint("D'un accès à Internet sur son terminal mobile")
                            termsBulletPoint("De la compatibilité du matériel et des logiciels destinés à utiliser le Service")
                        }
                    }
                    
                    // Article 3
                    termsArticle(number: 3, title: "Codes et sécurité", id: "article3") {
                        VStack(alignment: .leading, spacing: 12) {
                            termsParagraph("Le code personnel défini lors de l'inscription à DIAMACASH est strictement confidentiel. Le Client s'engage à le tenir secret et s'interdit de le communiquer à quiconque.")
                            termsParagraph("Le Client est entièrement responsable de la conservation et de l'utilisation de ses codes et, le cas échéant, des conséquences de leur divulgation et/ou de leur utilisation par des tiers.")
                            termsParagraph("Il appartient notamment au client de s'assurer que la conservation et la saisie de ses codes personnels soient effectuées dans des conditions parfaites de sécurité et de confidentialité.")
                            termsParagraph("Pour des raisons de sécurité, l'accès au Service pourra être bloqué temporairement au Client après composition à trois reprises d'un mot de passe erroné.")
                            termsParagraph("La Banque recommande de modifier le mot de passe de l'application DIAMACASH chaque 3 mois.")
                        }
                    }
                    
                    // Article 4
                    termsArticle(number: 4, title: "Évolutions du service", id: "article4") {
                        VStack(alignment: .leading, spacing: 12) {
                            termsParagraph("En fonction notamment des évolutions technologiques, la Banque apportera aux services de DIAMACASH les adaptations qui lui sembleront souhaitables. Elle en informera le client par tout moyen.")
                        }
                    }
                    
                    // Article 5
                    termsArticle(number: 5, title: "Assistance", id: "article5") {
                        VStack(alignment: .leading, spacing: 12) {
                            termsParagraph("La Banque met à disposition de l'utilisateur un service d'assistance via son Centre de relations clients (CRC).")
                        }
                    }
                    
                    // Article 6
                    termsArticle(number: 6, title: "Secret professionnel", id: "article6") {
                        VStack(alignment: .leading, spacing: 12) {
                            termsParagraph("La DIAMA BANK SA est tenue au secret professionnel conformément à la loi bancaire de la République de Guinée. Obligation légale est faite à son personnel de ne pas révéler les informations confidentielles dont il peut avoir connaissance. Cependant lorsque la loi le prévoit, le secret professionnel ne peut être opposé aux personnes, autorités ou organismes visés par cette dernière.")
                        }
                    }
                    
                    // Article 7
                    termsArticle(number: 7, title: "Responsabilité", id: "article7") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("LA BANQUE")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.greenH)
                            
                            termsParagraph("La DIAMA BANK SA s'engage à fournir le service selon les modalités définies au présent Contrat.")
                            termsParagraph("La Banque décline toute responsabilité en cas de dysfonctionnement dû à un défaut de compatibilité de l'équipement personnel du client ou de la configuration de son matériel.")
                            termsParagraph("La Banque n'est pas responsable des dysfonctionnements imputables aux fournisseurs d'accès et opérateurs de téléphonie mobile choisis par l'Utilisateur.")
                            
                            Text("LE CLIENT")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.greenH)
                                .padding(.top, 8)
                            
                            termsParagraph("Le Client doit prendre toute mesure pour conserver à tout moment en sa possession son smartphone et préserver la confidentialité de ses codes.")
                            termsParagraph("Le Client doit utiliser le service conformément aux finalités spécifiées dans le présent Contrat. Il assume les conséquences de l'utilisation du Service tant qu'il n'a pas fait une demande d'opposition (ou de blocage).")
                            termsParagraph("Le Client s'engage à mettre à jour les informations communiquées lors de l'inscription, en cas de changement de celles-ci.")
                            termsParagraph("Le Client est responsable des opérations effectuées via son Wallet DIAMACASH. La banque décline toute responsabilité liée à l'exécution d'une transaction par erreur à un autre bénéficiaire différent que celui souhaité ou un montant autre que celui voulu lors de l'action.")
                        }
                    }
                    
                    // Article 8
                    termsArticle(number: 8, title: "Interruption du service", id: "article8") {
                        VStack(alignment: .leading, spacing: 12) {
                            termsParagraph("La Banque peut bloquer l'accès total aux services DIAMACASH pour des raisons de sécurité ou de présomption d'opération non autorisée ou frauduleuse. Cette décision de blocage sera notifiée dans tous les cas au Client.")
                            termsParagraph("Le Service pourra être ponctuellement interrompu pour de courtes périodes pour des raisons d'ordre technique, notamment pour effectuer des opérations de maintenance.")
                        }
                    }
                    
                    // Article 9
                    termsArticle(number: 9, title: "Opposition ou blocage par le client", id: "article9") {
                        VStack(alignment: .leading, spacing: 12) {
                            termsParagraph("En cas de vol, de détournement ou de toute utilisation frauduleuse de ses codes d'accès ou de son smartphone, le Client doit en informer sans tarder la Banque aux fins de blocage de l'accès au Service.")
                            termsParagraph("Dans tous les cas, le client doit immédiatement :")
                            termsBulletPoint("Alerter la banque")
                            termsBulletPoint("Ou appeler le centre de relations clients (CRC) de la banque par téléphone")
                        }
                    }
                    
                    // Article 10
                    termsArticle(number: 10, title: "Tarification du service", id: "article10") {
                        VStack(alignment: .leading, spacing: 12) {
                            termsParagraph("Les services ci-après sont offerts gratuitement pour le détenteur du Wallet DIAMACASH :")
                            termsBulletPoint("La souscription au Wallet DIAMACASH")
                            termsBulletPoint("Le chargement du Wallet DIAMACASH")
                            termsBulletPoint("Le paiement chez le commerçant ou autres prestataires")
                            termsBulletPoint("La désinscription")
                            termsParagraph("Le Client conserve à sa charge les coûts de connexion facturés par son fournisseur d'accès Internet lors de l'utilisation du Service.")
                        }
                    }
                    
                    // Article 11
                    termsArticle(number: 11, title: "Durée du contrat - Résiliation", id: "article11") {
                        VStack(alignment: .leading, spacing: 12) {
                            termsParagraph("Le présent Contrat est conclu pour une durée indéterminée.")
                            termsParagraph("Il peut être résilié à tout moment par le Client dans son compte DIAMACASH ou par la Banque.")
                            termsParagraph("La résiliation par le Client prend effet trente (30) jours après la date de réception de sa demande de résiliation sous réserve de la bonne exécution des opérations de paiement effectuées au moyen du Service et encore en cours.")
                            termsParagraph("La résiliation par La Banque prend effet quinze jours (15) après la date d'envoi de sa notification au Client.")
                        }
                    }
                    
                    // Article 12
                    termsArticle(number: 12, title: "Modification du contrat", id: "article12") {
                        VStack(alignment: .leading, spacing: 12) {
                            termsParagraph("La Banque se réserve le droit d'apporter des modifications au présent Contrat, qui seront communiquées au Client par l'envoi d'un message via les canaux de communication de la banque, 30 jours avant la date de leur entrée en vigueur.")
                            termsParagraph("L'absence de contestation notifiée à La Banque avant l'expiration du délai précité vaut acceptation de ces modifications.")
                        }
                    }
                    
                    // Article 13
                    termsArticle(number: 13, title: "Arrêt du service", id: "article13") {
                        VStack(alignment: .leading, spacing: 12) {
                            termsParagraph("En cas d'arrêt de la fourniture du Service, le Client sera informé avec un préavis de trois (3) mois des dates et conditions d'arrêt de la fourniture du Service.")
                        }
                    }
                    
                    // Article 14
                    termsArticle(number: 14, title: "Loi applicable - Juridiction - Litiges", id: "article14") {
                        VStack(alignment: .leading, spacing: 12) {
                            termsParagraph("Le contrat est régi et interprété selon le droit Guinéen. Les parties déclarent se soumettre aux lois et règlements en vigueur en République de Guinée.")
                            termsParagraph("Tout différend y relatif quant à son interprétation ou son exécution, et qui n'aura pas été résolu à l'amiable sera porté devant les tribunaux compétents de Conakry.")
                        }
                    }
                    
                    // Footer
                    VStack(spacing: 8) {
                        Text("2025")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text("DIAMA BANK SA")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
                .padding(.bottom, 20)
            }
            .frame(maxHeight: 350)
            
            // Acceptance checkboxes
            VStack(alignment: .leading, spacing: 16) {
                Button(action: {
                    registrationData.acceptTerms.toggle()
                }) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: registrationData.acceptTerms ? "checkmark.square.fill" : "square")
                            .font(.system(size: 22))
                            .foregroundColor(registrationData.acceptTerms ? .greenH : .gray)
                        
                        Text("J'ai lu et j'accepte les Conditions Générales d'Utilisation")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                }
                
                Button(action: {
                    registrationData.acceptPrivacy.toggle()
                }) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: registrationData.acceptPrivacy ? "checkmark.square.fill" : "square")
                            .font(.system(size: 22))
                            .foregroundColor(registrationData.acceptPrivacy ? .greenH : .gray)
                        
                        Text("J'accepte le traitement de mes données personnelles conformément à la politique de confidentialité")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                }
            }
            .padding(.top, 10)
            
            // Read all sections requirement
        }
        .padding(.horizontal, 16)
    }
    
    // Helper view for terms sections
    private func termsSection<Content: View>(
        icon: String,
        title: String,
        id: String,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        let isExpanded = expandedTermsSections.contains(id)
        
        return VStack(spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    if isExpanded {
                        expandedTermsSections.remove(id)
                    } else {
                        expandedTermsSections.insert(id)
                    }
                }
            }) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(.greenH)
                        .font(.system(size: 16))
                        .frame(width: 24)
                    
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "checkmark.circle.fill" : "chevron.right")
                        .foregroundColor(isExpanded ? .green : .greenH)
                        .font(.system(size: 14, weight: .semibold))
                        .rotationEffect(.degrees(isExpanded ? 0 : 0))
                }
                .padding(12)
                .background(Color.white)
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    content()
                }
                .padding(12)
                .background(Color.white)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // Helper view for terms articles
    private func termsArticle<Content: View>(
        number: Int,
        title: String,
        id: String,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        let isExpanded = expandedTermsSections.contains(id)
        
        return VStack(spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    if isExpanded {
                        expandedTermsSections.remove(id)
                    } else {
                        expandedTermsSections.insert(id)
                    }
                }
            }) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.greenH.opacity(0.1))
                            .frame(width: 36, height: 36)
                        
                        Text("\(number)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.greenH)
                    }
                    
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "checkmark.circle.fill" : "chevron.right")
                        .foregroundColor(isExpanded ? .green : .greenH)
                        .font(.system(size: 14, weight: .semibold))
                        .rotationEffect(.degrees(isExpanded ? 0 : 0))
                }
                .padding(12)
                .background(Color.white)
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    content()
                }
                .padding(12)
                .background(Color.white)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func termsParagraph(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundColor(.primary)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private func termsBulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 10))
                .foregroundColor(.green)
                .padding(.top, 3)
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.primary)
        }
    }
    
    private func termsDefinitionItem(_ term: String, _ definition: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(Color.blueH)
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(term)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                Text(definition)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Step 5: OTP Verification
    private var step5OtpVerificationView: some View {
        VStack(spacing: 20) {
            Text("Vérifiez votre numéro de téléphone")
                .font(.system(size: 20, weight: .semibold))
            
            Text("Entrez le code de vérification envoyé au \(maskedPhoneNumber)")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            TextField("Entrez le code de vérification", text: $registrationData.otpCode)
                .keyboardType(.numberPad)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .onChange(of: registrationData.otpCode) {
                    if registrationData.otpCode.count > 6 {
                        registrationData.otpCode = String(registrationData.otpCode.prefix(6))
                    }
                }
            
            Button("Renvoyer le code OTP") {
                alertMessage = "Code OTP renvoyé"
                showAlert = true
            }
            .font(.system(size: 14))
            .foregroundColor(.blueH)
        }
        .padding(.horizontal)
    }
    
    private var maskedPhoneNumber: String {
        let phone = registrationData.phoneNumber
        if phone.count > 4 {
            return phone.prefix(3) + "****" + phone.suffix(3)
        }
        return "votre téléphone"
    }
    
    // MARK: - Step 6: Success
    private var step6SuccessView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(.green)
            
            Text("Félicitations!")
                .font(.system(size: 22, weight: .bold))
            
            Text("\(registrationData.firstName) \(registrationData.lastName)")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.green)
            
            Text("Votre compte a été créé avec succès.")
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 80)
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtonsView: some View {
        VStack(spacing: 15) {
            if currentStep < totalSteps {
                Button(action: nextStep) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(isLoading ? "CHARGEMENT..." : "SUIVANT")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(canProceedToNextStep() && !isLoading ? Color(red: 0.1, green: 0.4, blue: 0.1) : Color.gray)
                    .cornerRadius(8)
                }
                .disabled(isLoading || !canProceedToNextStep())
            } else {
                Button("Aller à la connexion") {
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color.blueH)
                .foregroundColor(.white)
                .fontWeight(.semibold)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
    }
    
    // MARK: - API Calls
    private func fetchNationalities() {
        isLoadingNationalities = true
        
        APIClient.shared.getNationalities { result in
            DispatchQueue.main.async {
                self.isLoadingNationalities = false
                
                switch result {
                case .success(let nationalitiesList):
                    self.nationalities = nationalitiesList
                    //print("✅ Loaded \(nationalitiesList.count) nationalities")
                    
                case .failure(let error):
                    //print("❌ Failed to load nationalities: \(error)")
                    // Load fallback nationalities
                    self.loadFallbackNationalities()
                }
            }
        }
    }
    
    private func fetchSecretQuestions() {
        isLoadingSecretQuestions = true
        
        let request = EmptyRequest()
        
        APIClient.shared.listSecretQuestions(request: request) { result in
            DispatchQueue.main.async {
                self.isLoadingSecretQuestions = false
                
                switch result {
                case .success(let response):
                    if response.respCode == "000", let resultList = response.result {
                        self.extractSecretQuestions(from: resultList)
                        //print("✅ Loaded \(self.secretQuestions.count) secret questions")
                    } else {
                        //print("❌ API returned error: \(response.message ?? "Unknown")")
                        self.loadFallbackSecretQuestions()
                    }
                    
                case .failure(let error):
                    //print("❌ Failed to load secret questions: \(error)")
                    self.loadFallbackSecretQuestions()
                }
            }
        }
    }
    
    private func extractSecretQuestions(from resultList: [Any]) {
        var questions: [SecretQuestion] = []
        
        for item in resultList {
            guard let dict = item as? [String: Any] else { continue }
            
            if let questionId = dict["questionId"] as? String,
               let questionText = dict["question"] as? String,
               !questionText.isEmpty {
                questions.append(SecretQuestion(id: questionId, question: questionText))
            }
        }
        
        self.secretQuestions = questions
    }
    
    private func loadFallbackNationalities() {
        nationalities = [
            Nationality(code: "GH", wording: "Ghanaian"),
            Nationality(code: "NG", wording: "Nigerian"),
            Nationality(code: "CI", wording: "Ivorian"),
            Nationality(code: "SN", wording: "Senegalese"),
            Nationality(code: "ML", wording: "Malian"),
            Nationality(code: "BF", wording: "Burkinabé"),
            Nationality(code: "TG", wording: "Togolese"),
            Nationality(code: "BJ", wording: "Beninese"),
            Nationality(code: "GN", wording: "Guinean"),
            Nationality(code: "LR", wording: "Liberian"),
            Nationality(code: "SL", wording: "Sierra Leonean"),
            Nationality(code: "GM", wording: "Gambian"),
            Nationality(code: "OT", wording: "Other")
        ]
    }
    
    private func loadFallbackSecretQuestions() {
        secretQuestions = [
            SecretQuestion(id: "01", question: "Quel est le nom de votre animal de compagnie ?"),
            SecretQuestion(id: "02", question: "Dans quelle ville êtes-vous né(e) ?"),
            SecretQuestion(id: "03", question: "Quel est le nom de jeune fille de votre mère ?"),
            SecretQuestion(id: "04", question: "Quel était le nom de votre première école ?"),
            SecretQuestion(id: "05", question: "Quel est votre livre préféré ?")
        ]
    }
    
    // MARK: - nextStep
    private func nextStep() {
        switch currentStep {
        case 1:
            if validatePersonalInfo() {
                withAnimation { currentStep += 1 }
            }
            
        case 2:
            if registrationData.pin.count != 4 {
                alertMessage = "Le PIN doit contenir 4 chiffres"
                showAlert = true
            } else if isWeakPin(registrationData.pin) {
                alertMessage = "Ce code PIN n'est pas sécurisé (ex: 0000, 1111, 1234). Veuillez en choisir un autre."
                showAlert = true
            } else if registrationData.pin != registrationData.confirmPin {
                alertMessage = "Les PINs ne correspondent pas"
                showAlert = true
            } else {
                withAnimation { currentStep += 1 }
            }
            
        case 3:
            if registrationData.selfieBase64.isEmpty || registrationData.idFrontBase64.isEmpty || registrationData.idBackBase64.isEmpty {
                alertMessage = "Veuillez capturer tous les documents requis"
                showAlert = true
                return
            }
            
            // Move to Terms and Conditions step
            withAnimation { currentStep += 1 }

        case 4:
         
            if !registrationData.acceptTerms || !registrationData.acceptPrivacy {
                alertMessage = "Veuillez accepter les conditions pour continuer"
                showAlert = true
                return
            }
            
            // Now submit registration
            isLoading = true
            submitRegistration()

        case 5:
            if registrationData.otpCode.count == 6 {
                isLoading = true
                verifyOtpCode()
            } else {
                alertMessage = "Please enter a valid OTP"
                showAlert = true
            }
            
        default:
            break
        }
    }
    
    // MARK: - PIN Security
    /// Rejects trivial PINs: repeated digits (0000, 1111), sequences (1234, 4321), and common weak codes.
    private func isWeakPin(_ pin: String) -> Bool {
        guard pin.count == 4, pin.allSatisfy(\.isNumber) else { return false }
        
        let weakPins: Set<String> = [
            "0000", "1111", "2222", "3333", "4444",
            "5555", "6666", "7777", "8888", "9999",
            "0123", "1234", "2345", "3456", "4567", "5678", "6789",
            "9876", "8765", "7654", "6543", "5432", "4321", "3210",
            "1122", "1212", "1000", "2000", "2580"
        ]
        
        if weakPins.contains(pin) { return true }
        
        // All identical digits
        if Set(pin).count == 1 { return true }
        
        // Strictly ascending or descending by 1
        let digits = pin.compactMap { Int(String($0)) }
        let isAscending = zip(digits, digits.dropFirst()).allSatisfy { $1 == $0 + 1 }
        let isDescending = zip(digits, digits.dropFirst()).allSatisfy { $1 == $0 - 1 }
        return isAscending || isDescending
    }
    
    // MARK: - Validation
    private func validatePersonalInfo() -> Bool {
        if registrationData.firstName.isEmpty {
            alertMessage = "First name is required"
            showAlert = true
            return false
        }
        
        if registrationData.lastName.isEmpty {
            alertMessage = "Last name is required"
            showAlert = true
            return false
        }
        
        if registrationData.phoneNumber.isEmpty {
            alertMessage = "Phone number is required"
            showAlert = true
            return false
        }
        
        if registrationData.phoneNumber.count != 9 || !registrationData.phoneNumber.allSatisfy(\.isNumber) {
            alertMessage = "Phone number must be 9 digits"
            showAlert = true
            return false
        }
        
        if registrationData.dateOfBirth.isEmpty {
            alertMessage = "Date of birth is required"
            showAlert = true
            return false
        }
        
        if registrationData.gender.isEmpty {
            alertMessage = "Please select a gender"
            showAlert = true
            return false
        }
        
        if registrationData.nationality.isEmpty {
            alertMessage = "Please select a nationality"
            showAlert = true
            return false
        }
        
        if registrationData.address.isEmpty {
            alertMessage = "Address is required"
            showAlert = true
            return false
        }
        
        if registrationData.secretQ.isEmpty {
            alertMessage = "Please select a secret question"
            showAlert = true
            return false
        }
        
        if registrationData.answer.isEmpty {
            alertMessage = "Secret answer is required"
            showAlert = true
            return false
        }
        
        if !registrationData.email.isEmpty && !isValidEmail(registrationData.email) {
            alertMessage = "Please enter a valid email address"
            showAlert = true
            return false
        }
        
        if !registrationData.nkinPhone.isEmpty {
            if registrationData.nkinPhone.count != 9 || !registrationData.nkinPhone.allSatisfy(\.isNumber) {
                alertMessage = "Next of kin phone number must be 9 digits"
                showAlert = true
                return false
            }
        }
        
        return true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // MARK: - Image Selection
    private func showSourceSelection() {
        #if targetEnvironment(simulator)
        imagePickerSourceType = .photoLibrary
        showImagePicker = true
        #else
        showingActionSheet = true
        #endif
    }

    private func handleImageSelection(_ image: UIImage) {
        guard let base64String = image.toBase64() else {
            alertMessage = "Erreur lors de la conversion de l'image"
            showAlert = true
            return
        }
        
        switch pickerType {
        case "selfie":
            registrationData.selfieBase64 = base64String
        case "idFront":
            registrationData.idFrontBase64 = base64String
        case "idBack":
            registrationData.idBackBase64 = base64String
        default:
            break
        }
    }
    
    // MARK: - API Submission
    private func submitRegistration() {
        let request = CustomerRegistrationRequest(
            firstName: registrationData.firstName,
            lastName: registrationData.lastName,
            phone: registrationData.phoneNumber,
            email: registrationData.email.isEmpty ? nil : registrationData.email,
            birthDate: registrationData.dateOfBirth,
            nationality: registrationData.nationality,
            documentCode: "NI",
            documentId: registrationData.documentId.isEmpty ? nil : registrationData.documentId,
            gender: registrationData.gender,
            currencyCode: "324",
            bank: "00100",
            branchCode: "001",
            secretQ: registrationData.secretQ,
            answer: registrationData.answer,
            address: registrationData.address,
            type: "P",
            productCode: "010",
            entityId: registrationData.phoneNumber,
            lastActionUser: nil,
            pin: registrationData.pin,
            nkinName: registrationData.nkinName.isEmpty ? nil : registrationData.nkinName,
            nkinPhone: registrationData.nkinPhone.isEmpty ? nil : registrationData.nkinPhone,
            srcFunds: nil,
            occupation: nil,
            estimatedIncome: nil,
            referralCode: nil,
            deviceId: APIClient.getDeviceId(),
            isFirstLogin: true,
            faceId: registrationData.selfieBase64,
            documentImg: registrationData.idFrontBase64,
            documentImgBack: registrationData.idBackBase64
        )
        
        APIClient.shared.registerCustomer(request: request) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    if response.respCode == "000" {
                        self.registrationData.authCode = response.authCode ?? ""
                        withAnimation { self.currentStep += 1 }
                    } else {
                        if response.respCode == "018" {
                            self.alertMessage = "Registration failed: Invalid data"
                        } else if response.respCode == "017" {
                            self.alertMessage = "Session expired, please restart registration"
                        } else {
                            self.alertMessage = response.message ?? "Registration failed"
                        }
                        self.showAlert = true
                    }
                case .failure(let error):
                    self.alertMessage = "Network error: \(error.localizedDescription)"
                    self.showAlert = true
                }
            }
        }
    }

    private func verifyOtpCode() {
        let request = OtpRequest(
            phoneNumber: registrationData.phoneNumber,
            authCode: registrationData.authCode,
            otp: registrationData.otpCode,
            entityId: nil
        )
        
        APIClient.shared.verifyOtp(request: request) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    if response.respCode == "000" {
                        withAnimation { self.currentStep += 1 }
                    } else {
                        if response.respCode == "018" {
                            self.alertMessage = "Incorrect OTP, please try again"
                        } else if response.respCode == "017" {
                            self.alertMessage = "Session expired, please restart registration"
                        } else {
                            self.alertMessage = response.message ?? "OTP verification failed"
                        }
                        self.showAlert = true
                    }
                case .failure(let error):
                    self.alertMessage = "Network error: \(error.localizedDescription)"
                    self.showAlert = true
                }
            }
        }
    }
    
    private func canProceedToNextStep() -> Bool {
        switch currentStep {
        case 1:
            return !registrationData.firstName.isEmpty &&
                   !registrationData.lastName.isEmpty &&
                   !registrationData.phoneNumber.isEmpty &&
                   !registrationData.dateOfBirth.isEmpty &&
                   !registrationData.gender.isEmpty &&
                   !registrationData.nationality.isEmpty &&
                   !registrationData.address.isEmpty &&
                   !registrationData.secretQ.isEmpty &&
                   !registrationData.answer.isEmpty
        case 2:
            return registrationData.pin.count == 4 &&
                   registrationData.confirmPin.count == 4 &&
                   registrationData.pin == registrationData.confirmPin &&
                   !isWeakPin(registrationData.pin)
        case 3:
            return !registrationData.selfieBase64.isEmpty &&
                   !registrationData.idFrontBase64.isEmpty &&
                   !registrationData.idBackBase64.isEmpty
        case 4:
            // Terms acceptance: must read all sections and check both boxes
            return 
                   registrationData.acceptTerms &&
                   registrationData.acceptPrivacy
        case 5:
            return registrationData.otpCode.count == 6
        default:
            return true
        }
    }
}


struct EmptyRequest: Codable {}

// MARK: - Searchable Nationality Picker
struct SearchableNationalityPicker: View {
    let nationalities: [Nationality]
    let isLoading: Bool
    @Binding var selectedNationality: String
    let onSelect: (Nationality) -> Void
    
    @State private var searchText = ""
    @State private var showSheet = false
    
    var filteredNationalities: [Nationality] {
        if searchText.isEmpty {
            return nationalities
        } else {
            return nationalities.filter { nationality in
                nationality.wording.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Nationalité*")
                    .font(.system(size: 16, weight: .medium))
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            
            Button(action: {
                showSheet = true
            }) {
                HStack {
                    Image(systemName: "flag.fill")
                        .foregroundColor(.blueH)
                        .frame(width: 20)
                    
                    Text(selectedNationality.isEmpty ? "Sélectionner une nationalité" : selectedNationality)
                        .foregroundColor(selectedNationality.isEmpty ? .gray : .primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
            .disabled(isLoading || nationalities.isEmpty)
        }
        .sheet(isPresented: $showSheet) {
            NavigationStack {
                VStack(spacing: 0) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Rechercher une nationalité...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding()
                    
                    // Results List
                    if filteredNationalities.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            
                            Text("Aucune nationalité trouvée")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(filteredNationalities, id: \.code) { nationality in
                                Button(action: {
                                    onSelect(nationality)
                                    searchText = ""
                                    showSheet = false
                                }) {
                                    HStack {
                                        Text(nationality.wording)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        if selectedNationality == nationality.wording {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blueH)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
                .navigationTitle("Sélectionner une nationalité")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Fermer") {
                            searchText = ""
                            showSheet = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Enhanced UI Components
struct CustomTextField: View {
    let title: String
    @Binding var text: String
    var icon: String? = nil
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(.blueH)
                        .frame(width: 20)
                }
                TextField(title.replacingOccurrences(of: "*", with: ""), text: $text)
                    .keyboardType(keyboardType)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct GenderButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.greenH : Color.clear)
                        .stroke(Color.greenH, lineWidth: 1)
                )
                .foregroundColor(isSelected ? .white : .greenH)
        }
    }
}

// MARK: - Enhanced RegistrationData
class RegistrationData: ObservableObject {
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var dateOfBirth = ""
    @Published var birthDate: Date?
    @Published var gender = ""
    @Published var phoneNumber = ""
    @Published var email = ""
    @Published var address = ""
    @Published var nationality = ""
    @Published var nationalityDisplay = ""
    @Published var documentId = ""
    @Published var documentType = "NI"
    @Published var pin = ""
    @Published var confirmPin = ""
    
    @Published var secretQ = ""
    @Published var secretQDisplay = ""
    @Published var answer = ""
    @Published var nkinName = ""
    @Published var nkinPhone = ""
    
    @Published var selfieBase64 = ""
    @Published var idFrontBase64 = ""
    @Published var idBackBase64 = ""
    
    @Published var authCode = ""
    @Published var otpCode = ""
    
    @Published var acceptTerms = false
    @Published var acceptPrivacy = false
}

// MARK: - Section Header Helper Function
private func sectionHeader(_ title: String) -> some View {
    HStack {
        Rectangle()
            .fill(Color.greenH)
            .frame(width: 4, height: 20)
            .cornerRadius(2)
        
        Text(title)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.blueH)
        
        Spacer()
    }
}

// MARK: - Enhanced Identification Card Component
@ViewBuilder
private func identificationCard(
    title: String,
    description: String,
    buttonText: String,
    systemIcon: String,
    isCompleted: Bool = false,
    isEnabled: Bool = true,
    action: @escaping () -> Void
) -> some View {
    VStack(alignment: .leading, spacing: 12) {
        HStack {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCompleted ? .green : .gray)
            
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isEnabled ? .primary : .gray)
        }
        
        Text(description)
            .font(.system(size: 14))
            .foregroundColor(.secondary)
        
        Button(action: action) {
            HStack {
                Image(systemName: systemIcon)
                Text(buttonText)
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                isEnabled ?
                (isCompleted ? Color.greenH : Color.blueH) :
                Color.gray
            )
            .cornerRadius(8)
        }
        .disabled(!isEnabled)
    }
    .padding()
    .background(
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isCompleted ? Color.green : Color.clear, lineWidth: 2)
            )
    )
    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
}

extension UIImage {
    func toBase64() -> String? {
        // Resize to max 1024px to reduce size
        let resized = self.resized(toMax: 1024)
        
        // Use 0.5 compression for balance between quality and size
        guard let imageData = resized.jpegData(compressionQuality: 0.5) else {
            return nil
        }
        
        return imageData.base64EncodedString()
    }
    
    func resized(toMax maxDimension: CGFloat) -> UIImage {
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        if ratio >= 1 { return self }
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - Enhanced ImagePicker
struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            picker.sourceType = sourceType
        } else {
            picker.sourceType = .photoLibrary
        }
        
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
    
}
#Preview {
    RegistrationFlowView()
        .environmentObject(AuthenticationManager())
}
