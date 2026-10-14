import SwiftUI

struct FAQView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    @State private var expandedIndex: Int? = nil
    
    // 🧠 Full FAQ list from the Android version
    let faqs: [(question: String, answer: String)] = [
        // --- Général ---
        ("Qu'est-ce que DIAMACASH ?", "DIAMACASH est votre portefeuille digital sécurisé permettant de gérer vos paiements, transferts et recharges facilement."),
        ("Comment m'inscrire à DIAMACASH ?", "Téléchargez l'application DIAMACASH sur l'Apple Store (iOS) ou Google Play (Android), ouvrez l'application, cliquez sur \"S'inscrire\" et suivez les étapes."),
        ("Comment me connecter à DIAMACASH ?", "Ouvrez l'application DIAMACASH, saisissez votre numéro de téléphone et votre code PIN puis cliquez sur 'Se connecter'."),
        ("J'ai oublié mon code PIN. Que dois-je faire ?", "Contactez le service client muni de votre pièce d'identité pour répondre aux questions de sécurité et initier la réinitialisation du mot de passe."),
        
        // --- Solde & compte ---
        ("Comment consulter le solde de mon portefeuille DIAMACASH ?", "Votre solde s'affiche dès votre connexion. S'il est masqué par des astérisques (*), appuyez sur l'œil pour l'afficher."),
        ("Pourquoi mon solde s'affiche-t-il sous forme d'astérisques (*) ?", "Par mesure de sécurité, le solde est masqué. Appuyez sur l'œil pour l'afficher."),
        ("Comment consulter l'historique de mes transactions ?", "Une fois connecté, cliquez sur \"Voir plus\" sous votre solde pour consulter la liste de vos transactions des 30 derniers jours."),
        
        // --- Transferts ---
        ("Comment envoyer de l'argent ?", "Cliquez sur \"Transfert interne\", puis suivez ces étapes :\n1. Sélectionnez la source des fonds\n2. Saisissez le numéro du bénéficiaire (9 chiffres)\n3. Vérifiez le destinataire\n4. Entrez le montant\n5. Cochez 'Ajouter les frais' si souhaité\n6. Ajoutez un commentaire (facultatif)\n7. Validez\n8. Entrez votre code PIN\n9. Confirmez le transfert."),
        ("Comment lier mon portefeuille DIAMACASH à mon compte bancaire DIAMA BANK SA ?", "Rendez-vous dans une agence DIAMA BANK SA muni de votre pièce d'identité pour initier la demande de liaison gratuitement."),
        ("Comment alimenter mon portefeuille DIAMACASH avec mon compte bancaire ?", "Cliquez sur \"Recharger mon wallet\" puis :\n1. Sélectionnez votre compte\n2. Saisissez le montant\n3. Ajoutez une référence (facultatif)\n4. Validez\n5. Entrez votre code PIN\n6. Confirmez le transfert."),
        ("Comment alimenter mon compte bancaire DIAMA BANK avec mon portefeuille DIAMACASH ?", "Cliquez sur \"Vers ma Banque\" puis :\n1. Sélectionnez votre compte\n2. Entrez le montant\n3. Ajoutez une référence (facultatif)\n4. Validez\n5. Entrez votre code PIN\n6. Confirmez."),
        ("À quelle fréquence mon solde est-il mis à jour ?", "Votre solde est mis à jour en temps réel à chaque ouverture ou actualisation manuelle de l'application."),
        
        // --- Types de transferts ---
        ("Quels types de transferts puis-je effectuer ?", "• Portefeuille vers Portefeuille\n• Portefeuille vers Compte Bancaire\n• Compte Bancaire vers Portefeuille\n• Mobile Money (via services partenaires)"),
        ("Y a-t-il des limites sur le montant que je peux transférer ?", "Oui, selon votre type de compte et votre niveau de vérification. Contactez le support pour plus d'informations."),
        ("Combien de temps prennent les transferts ?", "La plupart des transferts portefeuille à portefeuille sont instantanés."),
        
        // --- Paiements & services ---
        ("Puis-je acheter du crédit téléphonique via l'application ?", "Oui, vous pouvez acheter du crédit pour vous ou pour d'autres depuis l'application."),
        ("Qu'en est-il des forfaits données ?", "L'application permet l'achat de forfaits Internet pour plusieurs réseaux mobiles."),
        ("Puis-je payer des factures via DIAMACASH ?", "Oui, l'application permet le paiement de factures de services publics et autres."),
        ("Qu'est-ce qu'une Mise à disposition ?", "Les mises à disposition vous permettent de créer des bons que d'autres peuvent échanger contre de l'argent."),
        
        // --- Fonctionnalités avancées ---
        ("Que sont les Virements Permanents ?", "Ils permettent de planifier des transferts récurrents automatiques (ex: paiements mensuels)."),
        ("Que sont les Portefeuilles Sponsorisés ?", "Ils permettent de parrainer ou d'être parrainé par d'autres utilisateurs pour partager des fonds."),
        ("Qu'est-ce qu'un Portefeuille d'Épargne ?", "C'est une fonctionnalité qui vous aide à économiser séparément de votre solde principal."),
        ("Comment consulter mon historique de transactions ?", "Accédez à votre Mini Relevé depuis le menu pour voir vos transactions récentes."),
        
        // --- Sécurité ---
        ("Mon argent est-il en sécurité dans l'application ?", "Oui, DIAMACASH utilise le chiffrement et des protocoles sécurisés."),
        ("Puis-je changer mon code PIN ?", "Oui, allez dans le menu et sélectionnez \"Changer le PIN\"."),
        ("Que faire en cas d'accès non autorisé ?", "Changez immédiatement votre code PIN, vérifiez vos transactions et contactez le support."),
        ("Comment désactiver mon portefeuille ?", "Utilisez l'option \"Désactiver le Portefeuille\" dans le menu. Cette action peut être irréversible."),
        
        // --- Support client ---
        ("Comment contacter le support client ?", "• Appelez le 0612 00 86 99\n• Utilisez \"Nous Contacter\" dans l'application\n• Envoyez des commentaires via \"Envoyer des Commentaires\"."),
        ("Comment déclarer un incident ?", "Utilisez l'option \"Déclarer un incident\" dans le menu de navigation."),
        ("Puis-je envoyer des commentaires sur l'application ?", "Oui, utilisez l'option \"Envoyer des Commentaires\" dans le menu."),
        
        // --- Problèmes techniques ---
        ("L'application ne charge pas mon solde. Que faire ?", "1. Vérifiez votre connexion Internet\n2. Redémarrez l'application\n3. Appuyez sur l'œil pour actualiser\n4. Contactez le support si nécessaire."),
        ("J'ai des problèmes avec les transferts.", "Vérifiez :\n• Votre solde\n• Votre connexion Internet\n• Le numéro du destinataire\n• Vos limites de transfert."),
        ("Comment mettre à jour l'application ?", "Vérifiez sur le Play Store ou App Store pour installer la dernière version."),
        ("L'application plante souvent. Que faire ?", "1. Redémarrez l'appareil\n2. Videz le cache\n3. Mettez à jour l'application\n4. Contactez le support si le problème persiste."),
        
        // --- Compte utilisateur ---
        ("Comment me déconnecter ?", "Allez dans le menu et sélectionnez \"Déconnexion\"."),
        ("Puis-je utiliser l'application sur plusieurs appareils ?", "Oui, mais vous devrez valider avec un OTP lors d'une nouvelle connexion."),
        ("Que se passe-t-il si je désinstalle l'application ?", "Vos fonds restent en sécurité. Réinstallez l'application pour y accéder."),
        
        // --- Frais ---
        ("Y a-t-il des frais pour utiliser l'application ?", "Certaines transactions peuvent comporter des frais. Contactez le service client pour plus de détails.")
    ]
    
    // --- Filtrage FAQ ---
    var filteredFaqs: [(question: String, answer: String)] {
        if searchText.isEmpty {
            return faqs
        } else {
            return faqs.filter {
                $0.question.localizedCaseInsensitiveContains(searchText) ||
                $0.answer.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // --- Modern Header ---
                DiamaPayHeader()

                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // --- Barre de recherche moderne ---
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .font(.system(size: 16))
                            
                            TextField("Rechercher...", text: $searchText)
                                .font(.system(size: 15))
                            
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 16))
                                }
                            }
                        }
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // --- Cartes d'accès rapide modernes ---
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Besoin d'aide ?")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Color(UIColor.darkGray))
                                .padding(.horizontal, 20)
                            
                            HStack(spacing: 12) {
                                // Contact Card
                                VStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.blueH.opacity(0.1))
                                            .frame(width: 50, height: 50)
                                        
                                        Image(systemName: "phone.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(.blueH)
                                    }
                                    
                                    VStack(spacing: 4) {
                                        Text("Nous Contacter")
                                            .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(UIColor.darkGray))
                                        
                                        Text("+224 612 00 86 99")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.greenH)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                                
                                // Commentaires Card
                                VStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.greenH.opacity(0.1))
                                            .frame(width: 50, height: 50)
                                        
                                        Image(systemName: "bubble.left.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(.greenH)
                                    }
                                    
                                    VStack(spacing: 4) {
                                        Text("Commentaires")
                                            .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(UIColor.darkGray))
                                        
                                        Text("Donnez votre avis")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.blueH)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // --- Liste FAQ moderne ---
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Questions & Réponses")
                                    .font(.system(size: 20, weight: .bold))
            .foregroundColor(Color(UIColor.darkGray))
                                
                                Spacer()
                                
                                if !filteredFaqs.isEmpty {
                                    Text("\(filteredFaqs.count)")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.greenH)
                                        .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            if filteredFaqs.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray.opacity(0.5))
                                    
                                    Text("Aucun résultat trouvé")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.gray)
                                    
                                    Text("Essayez avec d'autres mots-clés")
                                        .font(.system(size: 13))
                                        .foregroundColor(.gray.opacity(0.7))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                VStack(spacing: 10) {
                                    ForEach(filteredFaqs.indices, id: \.self) { index in
                                        DisclosureGroup(
                                            isExpanded: Binding(
                                                get: { expandedIndex == index },
                                                set: { expandedIndex = $0 ? index : nil }
                                            )
                                        ) {
                                            Text(filteredFaqs[index].answer)
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                                .padding(.top, 8)
                                                .padding(.bottom, 12)
                                                .fixedSize(horizontal: false, vertical: true)
                                        } label: {
                                            HStack {
                                                Text(filteredFaqs[index].question)
                                                    .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(UIColor.darkGray))
                                                    .multilineTextAlignment(.leading)
                                                    .fixedSize(horizontal: false, vertical: true)
                                                
                                                Spacer()
                                            }
                                        }
                                        .padding(16)
                                        .background(Color.white)
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // --- Footer moderne ---
                        VStack(spacing: 12) {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.greenH)
                            
                            Text("Besoin d'aide supplémentaire ?")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text("Notre équipe est disponible 24/7 pour vous aider")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationView { FAQView() }
}
