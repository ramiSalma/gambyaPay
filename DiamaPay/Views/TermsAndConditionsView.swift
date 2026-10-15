import SwiftUI

struct TermsAndConditionsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var expandedSections: Set<String> = []
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ZStack {
                    Color(hex: "174EA6")
                    HStack(spacing: 14) {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 21, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 42, height: 48, alignment: .leading)
                        }
                        Spacer(minLength: 0)
                        Text("Conditions Générales")
                            .font(.system(size: 19, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Spacer(minLength: 0)
                        Color.clear.frame(width: 42, height: 48)
                    }
                    .padding(.horizontal, 22)
                }
                .frame(height: 58)
                .background(Color(hex: "174EA6").ignoresSafeArea(edges: .top))

                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Conditions Générales d'Utilisation")
                        .font(.system(size: 27, weight: .bold))
                        .foregroundColor(.gray)
                    
                    Text("DIAMACASH - DIAMA BANK SA")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "0788B9"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 26)
                .padding(.bottom, 30)
                .background(Color.white)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Color.orange.opacity(0.25)).frame(height: 2)
                }
                
                // Modern Terms Content ScrollView
                ScrollView {
                    LazyVStack(spacing: 14) {
                        // Definitions Section
                        modernSection(
                            icon: "book.fill",
                            title: "Définitions",
                            id: "definitions"
                        ) {
                            definitionsContent
                        }
                        
                        // Object Section
                        modernSection(
                            icon: "target",
                            title: "Objet",
                            id: "object"
                        ) {
                            objectContent
                        }
                        
                        // Features Section
                        modernSection(
                            icon: "star.fill",
                            title: "Fonctionnalités du service",
                            id: "features"
                        ) {
                            featuresContent
                        }
                        
                        // Articles
                        ForEach(articles, id: \.number) { article in
                            modernArticle(article: article)
                        }
                        
                        // Footer
                        footerView
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 18)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AppBottomBar(onSponsors: {}, onQR: {}, onLimits: {}, onSettings: {})
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Modern Section
    private func modernSection<Content: View>(
        icon: String,
        title: String,
        id: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let isExpanded = expandedSections.contains(id)
        
        return VStack(spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    if isExpanded {
                        expandedSections.remove(id)
                    } else {
                        expandedSections.insert(id)
                    }
                }
            }) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(Color(hex: "174EA6"))
                        .font(.system(size: 24, weight: .semibold))
                        .frame(width: 46, height: 46)
                    
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.gray)

                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color(hex: "174EA6"))
                        .font(.system(size: 18, weight: .semibold))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .background(Color.white)
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    content()
                }
                .padding(20)
                .background(Color.white)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.white)
        .cornerRadius(23)
        .overlay(RoundedRectangle(cornerRadius: 23).stroke(Color.black.opacity(0.06), lineWidth: 1))
        .shadow(color: .black.opacity(0.12), radius: 5, x: 0, y: 3)
    }
    
    // MARK: - Definitions Content
    private var definitionsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            modernParagraph("Pour les besoins du présent contrat, il convient d'entendre par :")
            
            modernDefinitionItem("Banque", "La DIAMA BANK SA.")
            modernDefinitionItem("Contrat", "Désigne le présent contrat d'adhésion au service DIAMACASH, ses Conditions Générales de fonctionnement, ses Conditions Particulières ainsi que tout document annexe et avenant, qui constitue un tout indivisible.")
            modernDefinitionItem("Application mobile", "Une application mobile est un logiciel applicatif développé pour un appareil électronique mobile, tel qu'un assistant personnel, un téléphone portable, un smartphone…")
            modernDefinitionItem("Wallet", "Constitue un moyen de paiement permettant à son détenteur de stocker de façon sécurisée dans un portefeuille numérique, de la monnaie électronique en vue d'effectuer des paiements, d'émettre ou de recevoir des transferts d'argent ainsi que de faire du cash in et du cash out.")
            modernDefinitionItem("Etablissement", "Désigne tout établissement bancaire ou les établissements de paiement.")
            modernDefinitionItem("Cash-In", "Il s'agit d'une opération de dépôt d'espèce au niveau du Wallet.")
            modernDefinitionItem("Cash-Out", "Il s'agit d'une opération de retrait d'espèce à partir du Wallet, auprès d'un distributeur agréé par la DIAMA BANK SA.")
            modernDefinitionItem("Compte de rattachement", "Désigne le compte ouvert dans les livres de la Banque tel que précisé dans le Bulletin d'Adhésion et sur lequel est rattaché le Wallet.")
            modernDefinitionItem("Détenteur du Wallet", "Peut-être le titulaire du compte ou toute autre personne nommément désignée dans le présent contrat.")
            modernDefinitionItem("DIAMACASH", "Désigne l'application de paiement mobile pour les clients à titre privé.")
            modernDefinitionItem("DAB/GAB", "Appareils de distribution automatique de billets de Banque.")
            modernDefinitionItem("TPE", "Terminal de Paiement Electronique.")
        }
    }
    
    // MARK: - Object Content
    private var objectContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            modernParagraph("Le Wallet DIAMACASH est un moyen de paiement électronique sécurisé, pouvant être lié au compte bancaire du client ouvert dans les livres de la DIAMA BANK SA, qui permet à son titulaire d'effectuer en temps réel différents services de paiement et de transfert d'argent et ce, via l'application mobile DIAMACASH.")
            modernParagraph("Cette application est téléchargeable à partir de Google Play et Apple Store.")
        }
    }
    
    // MARK: - Features Content
    private var featuresContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            modernParagraph("Les fonctionnalités disponibles au niveau de l'application DIAMACASH sont :")
            
            modernDefinitionItem("La souscription", "Le client peut initier directement son inscription sur l'application DIAMACASH en renseignant les formulaires associés ou se rendre soit chez un agent agréé, soit en agence pour se faire assister pour son inscription.")
            
            modernDefinitionItem("La connexion", "Le client se connecte à son compte DIAMACASH à l'aide de son numéro de téléphone et de son code secret. Lors de la toute première connexion, il lui sera demandé de saisir un code de confirmation qu'il recevra par sms pour des raisons de sécurité.")
            
            modernDefinitionItem("La liaison de son compte bancaire", "Le client qui a un compte bancaire ouvert dans les livres de la DIAMA BANK SA peut se rendre en agence pour demander la liaison de son compte et ainsi effectuer les opérations de transfert gratuitement entre son compte DIAMACASH et son compte bancaire.")
            
            modernDefinitionItem("Le déplafonnement du wallet", "Par défaut, le compte DIAMACASH du client est limité à un solde maximum de 5.000.000 GNF lors de l'ouverture de son compte à distance. Il peut cependant se rendre en agence ou chez un distributeur agréé pour signer la convention de contrat et demander le déplafonnement de son compte DIAMACASH.")
            
            modernDefinitionItem("Le Chargement du Wallet (Cash-In)", "Le détenteur du Wallet peut bénéficier de deux canaux de chargement : Chargement au niveau des distributeurs en faisant un versement espèces, ou Chargement via son compte bancaire DIAMA BANK SA lié à son wallet.")
            
            modernDefinitionItem("Retrait d'argent (Cash-Out)", "Le client peut se rendre chez n'importe quels distributeurs pour effectuer un retrait sur son compte DIAMACASH.")
            
            modernDefinitionItem("Transfert vers un autre compte DIAMACASH", "Le client peut à tout moment effectuer des transferts d'argent à un autre wallet client dans la limite de son solde et de ces autorisations.")
            
            modernDefinitionItem("Transfert vers ma banque", "Le client peut à tout moment effectuer des transferts d'argent vers son compte bancaire DIAMA BANK SA qui a été au préalable lié à son wallet.")
            
            modernDefinitionItem("Transfert de ma banque", "Le client peut à tout moment effectuer des transferts d'argent depuis son compte bancaire DIAMA BANK SA qui a été au préalable lié à son wallet.")
            
            modernDefinitionItem("Mise à disposition", "Le client peut à tout moment effectuer des transferts d'argent à une personne n'ayant pas de compte DIAMACASH.")
            
            modernDefinitionItem("Parrainage", "Le client peut à tout moment effectuer le parrainage d'un autre compte DIAMACASH.")
            
            modernDefinitionItem("Virement permanent", "Le client peut à tout moment initier des virements permanents vers un autre compte DIAMACASH.")
            
            modernDefinitionItem("Paiement chez le commerçant", "Le Client peut payer ses achats à partir de son Wallet DIAMACASH, auprès des commerçants accepteurs détenant un Wallet DIAMACASH PRO.")
        }
    }
    
    // MARK: - Modern Article
    private func modernArticle(article: Article) -> some View {
        let isExpanded = expandedSections.contains(article.id)
        
        return VStack(spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    if isExpanded {
                        expandedSections.remove(article.id)
                    } else {
                        expandedSections.insert(article.id)
                    }
                }
            }) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "F1F8F2"))
                            .frame(width: 52, height: 52)
                        
                        Text("\(article.number)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(hex: "174EA6"))
                    }
                    
                    Text(article.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color(hex: "174EA6"))
                        .font(.system(size: 18, weight: .semibold))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .background(Color.white)
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    article.content()
                }
                .padding(20)
                .background(Color.white)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.white)
        .cornerRadius(23)
        .overlay(RoundedRectangle(cornerRadius: 23).stroke(Color.black.opacity(0.06), lineWidth: 1))
        .shadow(color: .black.opacity(0.12), radius: 5, x: 0, y: 3)
    }
    
    // MARK: - Helper Views
    private func modernParagraph(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundColor(.black.opacity(0.85))
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private func modernDefinitionItem(_ title: String, _ definition: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.blueH)
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                
                Text(definition)
                    .font(.system(size: 13))
                    .foregroundColor(.black.opacity(0.7))
            }
        }
    }
    
    private func modernBulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(.green)
                .padding(.top, 3)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.black.opacity(0.85))
        }
    }
    
    private var footerView: some View {
        VStack(spacing: 12) {
            
            Text("2025")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.black)
            
            Text("DIAMA BANK SA")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .overlay(alignment: .top) {
            Rectangle().fill(Color.orange.opacity(0.25)).frame(height: 2)
        }
    }
    
    // MARK: - Articles Data
    private var articles: [Article] {
        [
            Article(number: 1, title: "Conditions d'inscription au service", id: "article1") {
                VStack(alignment: .leading, spacing: 12) {
                    modernParagraph("Le Service est réservé à la clientèle des particuliers, personnes physiques majeures titulaires disposant :")
                    modernBulletPoint("D'un smartphone compatible avec Play Store ou Apple Store")
                    modernBulletPoint("D'un numéro mobile guinéen en leur nom")
                    modernParagraph("L'utilisation de DIAMACASH se fait en Guinée comme à l'étranger.")
                }
            },
            Article(number: 2, title: "Accès au service", id: "article2") {
                VStack(alignment: .leading, spacing: 12) {
                    modernParagraph("L'accès au service est subordonné au respect par l'Utilisateur des dispositions de ce contrat.")
                    
                    Text("Moyens techniques :")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(UIColor.darkGray))
                        .padding(.top, 8)
                    
                    modernParagraph("L'accès au Service se fait via l'utilisation d'Internet au moyen d'un terminal mobile. L'Utilisateur s'assure de disposer à minima :")
                    modernBulletPoint("D'un smartphone, de sa mise en service et de sa maintenance")
                    modernBulletPoint("D'un accès à Internet sur son terminal mobile")
                    modernBulletPoint("De la compatibilité du matériel et des logiciels destinés à utiliser le Service")
                }
            },
            Article(number: 3, title: "Codes et sécurité", id: "article3") {
                VStack(alignment: .leading, spacing: 12) {
                    modernParagraph("Le code personnel défini lors de l'inscription à DIAMACASH est strictement confidentiel. Le Client s'engage à le tenir secret et s'interdit de le communiquer à quiconque.")
                    modernParagraph("Le Client est entièrement responsable de la conservation et de l'utilisation de ses codes et, le cas échéant, des conséquences de leur divulgation et/ou de leur utilisation par des tiers.")
                    modernParagraph("Il appartient notamment au client de s'assurer que la conservation et la saisie de ses codes personnels soient effectuées dans des conditions parfaites de sécurité et de confidentialité.")
                    modernParagraph("Pour des raisons de sécurité, l'accès au Service pourra être bloqué temporairement au Client après composition à trois reprises d'un mot de passe erroné.")
                    modernParagraph("La Banque recommande de modifier le mot de passe de l'application DIAMACASH chaque 3 mois.")
                }
            },
            Article(number: 4, title: "Évolutions du service", id: "article4") {
                VStack(alignment: .leading, spacing: 12) {
                    modernParagraph("En fonction notamment des évolutions technologiques, la Banque apportera aux services de DIAMACASH les adaptations qui lui sembleront souhaitables. Elle en informera le client par tout moyen.")
                }
            },
            Article(number: 5, title: "Assistance", id: "article5") {
                VStack(alignment: .leading, spacing: 12) {
                    modernParagraph("La Banque met à disposition de l'utilisateur un service d'assistance via son Centre de relations clients (CRC).")
                }
            },
            Article(number: 6, title: "Secret professionnel", id: "article6") {
                VStack(alignment: .leading, spacing: 12) {
                    modernParagraph("La DIAMA BANK SA est tenue au secret professionnel conformément à la loi bancaire de la République de Guinée. Obligation légale est faite à son personnel de ne pas révéler les informations confidentielles dont il peut avoir connaissance. Cependant lorsque la loi le prévoit, le secret professionnel ne peut être opposé aux personnes, autorités ou organismes visés par cette dernière.")
                }
            },
            Article(number: 7, title: "Responsabilité", id: "article7") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("LA BANQUE")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.blueH)
                    
                    modernParagraph("La DIAMA BANK SA s'engage à fournir le service selon les modalités définies au présent Contrat.")
                    modernParagraph("La Banque décline toute responsabilité en cas de dysfonctionnement dû à un défaut de compatibilité de l'équipement personnel du client ou de la configuration de son matériel.")
                    modernParagraph("La Banque n'est pas responsable des dysfonctionnements imputables aux fournisseurs d'accès et opérateurs de téléphonie mobile choisis par l'Utilisateur.")
                    
                    Text("LE CLIENT")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.blueH)
                        .padding(.top, 8)
                    
                    modernParagraph("Le Client doit prendre toute mesure pour conserver à tout moment en sa possession son smartphone et préserver la confidentialité de ses codes.")
                    modernParagraph("Le Client doit utiliser le service conformément aux finalités spécifiées dans le présent Contrat. Il assume les conséquences de l'utilisation du Service tant qu'il n'a pas fait une demande d'opposition (ou de blocage).")
                    modernParagraph("Le Client s'engage à mettre à jour les informations communiquées lors de l'inscription, en cas de changement de celles-ci.")
                    modernParagraph("Le Client est responsable des opérations effectuées via son Wallet DIAMACASH. La banque décline toute responsabilité liée à l'exécution d'une transaction par erreur à un autre bénéficiaire différent que celui souhaité ou un montant autre que celui voulu lors de l'action.")
                }
            },
            Article(number: 8, title: "Interruption du service", id: "article8") {
                VStack(alignment: .leading, spacing: 12) {
                    modernParagraph("La Banque peut bloquer l'accès total aux services DIAMACASH pour des raisons de sécurité ou de présomption d'opération non autorisée ou frauduleuse. Cette décision de blocage sera notifiée dans tous les cas au Client.")
                    modernParagraph("Le Service pourra être ponctuellement interrompu pour de courtes périodes pour des raisons d'ordre technique, notamment pour effectuer des opérations de maintenance.")
                }
            },
            Article(number: 9, title: "Opposition ou blocage par le client", id: "article9") {
                VStack(alignment: .leading, spacing: 12) {
                    modernParagraph("En cas de vol, de détournement ou de toute utilisation frauduleuse de ses codes d'accès ou de son smartphone, le Client doit en informer sans tarder la Banque aux fins de blocage de l'accès au Service.")
                    modernParagraph("Dans tous les cas, le client doit immédiatement :")
                    modernBulletPoint("Alerter la banque")
                    modernBulletPoint("Ou appeler le centre de relations clients (CRC) de la banque par téléphone")
                }
            },
            Article(number: 10, title: "Tarification du service", id: "article10") {
                VStack(alignment: .leading, spacing: 12) {
                    modernParagraph("Les services ci-après sont offerts gratuitement pour le détenteur du Wallet DIAMACASH :")
                    modernBulletPoint("La souscription au Wallet DIAMACASH")
                    modernBulletPoint("Le chargement du Wallet DIAMACASH")
                    modernBulletPoint("Le paiement chez le commerçant ou autres prestataires")
                    modernBulletPoint("La désinscription")
                    modernParagraph("Le Client conserve à sa charge les coûts de connexion facturés par son fournisseur d'accès Internet lors de l'utilisation du Service.")
                }
            },
            Article(number: 11, title: "Durée du contrat - Résiliation", id: "article11") {
                VStack(alignment: .leading, spacing: 12) {
                    modernParagraph("Le présent Contrat est conclu pour une durée indéterminée.")
                    modernParagraph("Il peut être résilié à tout moment par le Client dans son compte DIAMACASH ou par la Banque.")
                    modernParagraph("La résiliation par le Client prend effet trente (30) jours après la date de réception de sa demande de résiliation sous réserve de la bonne exécution des opérations de paiement effectuées au moyen du Service et encore en cours.")
                    modernParagraph("La résiliation par La Banque prend effet quinze jours (15) après la date d'envoi de sa notification au Client.")
                }
            },
            Article(number: 12, title: "Modification du contrat", id: "article12") {
                VStack(alignment: .leading, spacing: 12) {
                    modernParagraph("La Banque se réserve le droit d'apporter des modifications au présent Contrat, qui seront communiquées au Client par l'envoi d'un message via les canaux de communication de la banque, 30 jours avant la date de leur entrée en vigueur.")
                    modernParagraph("L'absence de contestation notifiée à La Banque avant l'expiration du délai précité vaut acceptation de ces modifications.")
                }
            },
            Article(number: 13, title: "Arrêt du service", id: "article13") {
                VStack(alignment: .leading, spacing: 12) {
                    modernParagraph("En cas d'arrêt de la fourniture du Service, le Client sera informé avec un préavis de trois (3) mois des dates et conditions d'arrêt de la fourniture du Service.")
                }
            },
            Article(number: 14, title: "Loi applicable - Juridiction - Litiges", id: "article14") {
                VStack(alignment: .leading, spacing: 12) {
                    modernParagraph("Le contrat est régi et interprété selon le droit Guinéen. Les parties déclarent se soumettre aux lois et règlements en vigueur en République de Guinée.")
                    modernParagraph("Tout différend y relatif quant à son interprétation ou son exécution, et qui n'aura pas été résolu à l'amiable sera porté devant les tribunaux compétents de Conakry.")
                }
            }
        ]
    }
}

// MARK: - Article Model
struct Article {
    let number: Int
    let title: String
    let id: String
    let content: () -> AnyView
    
    init(number: Int, title: String, id: String, @ViewBuilder content: @escaping () -> some View) {
        self.number = number
        self.title = title
        self.id = id
        self.content = { AnyView(content()) }
    }
}

// MARK: - Preview
struct TermsAndConditionsView_Previews: PreviewProvider {
    static var previews: some View {
        TermsAndConditionsView()
    }
}
