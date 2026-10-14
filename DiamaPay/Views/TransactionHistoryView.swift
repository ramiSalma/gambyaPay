import SwiftUI

struct TransactionHistoryView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var startDate = "23/08/2025"
    @State private var endDate = "22/09/2025"
    @State private var showStartDatePicker = false
    @State private var showEndDatePicker = false
    @State private var selectedStartDate = Date()
    @State private var selectedEndDate = Date()
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    // Transaction data
    @State private var transactions: [Transaction] = []
    @State private var allTransactions: [Transaction] = []
    @State private var filteredTransactions: [Transaction] = []
    
    // Pagination
    @State private var currentPage = 1
    @State private var totalPages = 1
    private let pageSize = 5
    
    var body: some View {
        NavigationStack {

        ZStack {
            // Background color
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
                        
                        Text("Chargement des transactions...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    // Content
                    ScrollView {
                        VStack(spacing: 20) {
                            // Blue title card
                            titleCard
                            
                            // Filter section
                            filterSection
                            
                            // Transactions section
                            if !transactions.isEmpty {
                                transactionsSection
                                
                                // Pagination
                                if totalPages > 1 {
                                    paginationSection
                                }
                            } else if !isLoading {
                                emptyStateView
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                    }
                }
            }
        }
        }
        .navigationBarHidden(true)
        .onAppear {
            setDefaultDateRange()
            loadLast30DaysTransactions()
        }
        .alert("Erreur", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Une erreur s'est produite")
        }
        .sheet(isPresented: $showStartDatePicker) {
            DatePickerSheet(
                selectedDate: $selectedStartDate,
                dateString: $startDate,
                title: "Date de début"
            )
        }
        .sheet(isPresented: $showEndDatePicker) {
            DatePickerSheet(
                selectedDate: $selectedEndDate,
                dateString: $endDate,
                title: "Date de fin"
            )
        }
    }
    
   
    
    // MARK: - Title Card
    private var titleCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blueH)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            VStack {
                Text("Dernières transactions")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                // Underline
                Rectangle()
                    .fill(.white)
                    .frame(width: 60, height: 2)
                    .padding(.top, 4)
            }
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Filter Section
    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Filtrer par date")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0.1, green: 0.4, blue: 0.1))
                
        
            }
            HStack {
                Rectangle()
                    .fill(.blueH)
                    .frame(width: 60, height: 3)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                
                Spacer()
            }
            
            // Date inputs
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date de début")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        showStartDatePicker = true
                    }) {
                        HStack {
                            Text(startDate)
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "calendar")
                                .foregroundColor(.blueH)
                                .font(.system(size: 16))
                        }
                        .padding(12)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date de fin")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        showEndDatePicker = true
                    }) {
                        HStack {
                            Text(endDate)
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "calendar")
                                .foregroundColor(.blueH)
                                .font(.system(size: 16))
                        }
                        .padding(12)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: {
                    resetFilters()
                }) {
                    Text("Réinitialiser")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.greenH)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Button(action: {
                    filterTransactions()
                }) {
                    Text("Filtrer")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.greenH)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Transactions Section
    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("30 derniers jours")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 0.1, green: 0.4, blue: 0.1))
                    
                    if totalPages > 1 {
                        Text("Page \(currentPage) sur \(totalPages) (\(filteredTransactions.count) transactions)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(filteredTransactions.count) transaction\(filteredTransactions.count > 1 ? "s" : "")")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // Blue underline
            HStack {
                Rectangle()
                    .fill(.blueH)
                    .frame(width: 40, height: 3)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                
                Spacer()
            }
            
            // Transaction list
            VStack(spacing: 12) {
                ForEach(transactions) { transaction in
                    transactionRow(transaction)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
 
    private func transactionRow(_ transaction: Transaction) -> some View {
        NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
            VStack(spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(transaction.date)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text(transaction.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        Text(transaction.reference)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)

                        Text("Frais: \(transaction.fees)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)

                        Text(transaction.balance)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(transaction.amount)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(transaction.isPositive ? .green : .red)
                        .multilineTextAlignment(.trailing)
                }

                // Separator line
                if transaction.id != transactions.last?.id {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 0.5)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle()) // remove default blue highlight
    }

    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("Aucune transaction trouvée")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("Il n'y a pas de transactions pour la période sélectionnée")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Actualiser") {
                loadLast30DaysTransactions()
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.blueH)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(40)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Pagination Section
    private var paginationSection: some View {
        VStack(spacing: 12) {
            // Page info
            Text("Page \(currentPage) sur \(totalPages)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            // Navigation buttons
            HStack(spacing: 8) {
                Button("<<") {
                    goToPage(1)
                }
                .disabled(currentPage <= 1)
                .buttonStyle(PaginationButtonStyle(isDisabled: currentPage <= 1))
                
                Button("<") {
                    goToPage(currentPage - 1)
                }
                .disabled(currentPage <= 1)
                .buttonStyle(PaginationButtonStyle(isDisabled: currentPage <= 1))
                
                Spacer()
                
                Button(">") {
                    goToPage(currentPage + 1)
                }
                .disabled(currentPage >= totalPages)
                .buttonStyle(PaginationButtonStyle(isDisabled: currentPage >= totalPages))
                
                Button(">>") {
                    goToPage(totalPages)
                }
                .disabled(currentPage >= totalPages)
                .buttonStyle(PaginationButtonStyle(isDisabled: currentPage >= totalPages))
            }
            
            // Page numbers (show 5 pages max)
            HStack(spacing: 4) {
                let startPage = max(1, currentPage - 2)
                let endPage = min(totalPages, currentPage + 2)
                
                ForEach(startPage...endPage, id: \.self) { page in
                    Button("\(page)") {
                        goToPage(page)
                    }
                    .buttonStyle(PageNumberButtonStyle(isSelected: page == currentPage))
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - API Methods
    private func loadLast30DaysTransactions() {
       
        
        let walletNumber = UserDataManager.shared.getWalletNumber()
        let pin = UserDataManager.shared.getPinForAPI()
        
        guard !walletNumber.isEmpty else {
            showErrorMessage("Numéro de wallet non trouvé")
            return
        }
        
        isLoading = true
        
        let request = RequestEStatement(walletNumber: walletNumber, pin: pin)
        
        APIClient.shared.getLast30DaysTransactions(request: request) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.isSuccessful {
                        self.processTransactionsResponse(response)
                    } else {
                        self.showErrorMessage("Erreur: \(response.message ?? "Erreur inconnue")")
                    }
                    
                case .failure(let error):
                    if let apiError = error as? APIError {
                        self.showErrorMessage("Erreur: \(apiError.message)")
                    } else {
                        self.showErrorMessage("Erreur de connexion: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func processTransactionsResponse(_ response: JResponseService) {
        allTransactions.removeAll()
        filteredTransactions.removeAll()
        transactions.removeAll()
        
        guard let results = response.result, !results.isEmpty else {
            //print("No transactions found")
            return
        }
        
        // Convert API results to Transaction objects
        for result in results {
            let transaction = Transaction(from: result)
            allTransactions.append(transaction)
        }
        
        //print("Processed \(allTransactions.count) transactions")
        
        filteredTransactions = allTransactions
        loadFirstPage()
        
        // Show success message if there are transactions
        if !allTransactions.isEmpty && totalPages > 1 {
            // Could show a toast message here
        }
    }
    
    private func loadFirstPage() {
        currentPage = 1
        calculateTotalPages()
        loadPageData()
    }
    
    private func calculateTotalPages() {
        totalPages = max(1, Int(ceil(Double(filteredTransactions.count) / Double(pageSize))))
    }
    
    private func loadPageData() {
        let startIndex = (currentPage - 1) * pageSize
        let endIndex = min(startIndex + pageSize, filteredTransactions.count)
        
        if startIndex < filteredTransactions.count {
            transactions = Array(filteredTransactions[startIndex..<endIndex])
        } else {
            transactions = []
        }
    }
    
    private func goToPage(_ page: Int) {
        guard page >= 1 && page <= totalPages && page != currentPage else { return }
        
        currentPage = page
        loadPageData()
    }
    
    private func filterTransactions() {
        guard !startDate.isEmpty, !endDate.isEmpty else {
            showErrorMessage("Veuillez sélectionner les dates")
            return
        }
        
        if allTransactions.isEmpty {
            loadLast30DaysTransactions()
            return
        }
        
        filterTransactionsByDateRange()
    }
    
    private func filterTransactionsByDateRange() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        guard let fromDate = dateFormatter.date(from: startDate),
              let toDate = dateFormatter.date(from: endDate) else {
            showErrorMessage("Format de date invalide")
            return
        }
        
        // Validate date range
        guard fromDate <= toDate else {
            showErrorMessage("La date de début doit être antérieure à la date de fin")
            return
        }
        
        filteredTransactions = allTransactions.filter { transaction in
            guard let transactionDateStr = transaction.transactionDate,
                  let transactionDate = dateFormatter.date(from: transactionDateStr) else {
                return false
            }
            
            return transactionDate >= fromDate && transactionDate <= toDate
        }
        
        loadFirstPage()
        
        // Show result message
        let message = filteredTransactions.isEmpty ?
            "Aucune transaction trouvée pour cette période" :
            "\(filteredTransactions.count) transaction\(filteredTransactions.count > 1 ? "s" : "") trouvée\(filteredTransactions.count > 1 ? "s" : "")"
        
        //print(message) // You could show this as a toast message
    }
    
    private func resetFilters() {
        setDefaultDateRange()
        filteredTransactions = allTransactions
        loadFirstPage()
        //print("Affichage de toutes les transactions") // Toast message
    }
    
    
    
    private func setDefaultDateRange() {
        let calendar = Calendar.current
        let today = Date()
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today) ?? today
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        startDate = dateFormatter.string(from: thirtyDaysAgo)
        endDate = dateFormatter.string(from: today)
        
        selectedStartDate = thirtyDaysAgo
        selectedEndDate = today
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}
// MARK: - Supporting Models

struct PaginationButtonStyle: ButtonStyle {
    let isDisabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(isDisabled ? .gray : .blueH)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isDisabled ? Color.gray.opacity(0.1) : Color.blueH.opacity(0.1))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct PageNumberButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(isSelected ? .white : .blueH)
            .frame(width: 32, height: 32)
            .background(
                Circle()
                    .fill(isSelected ? Color.blueH : Color.blueH.opacity(0.1))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - Date Picker Sheet
struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Binding var dateString: String
    let title: String
    @Environment(\.presentationMode) var presentationMode
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    title,
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(WheelDatePickerStyle())
                .padding()
                
                Spacer()
            }
            .navigationTitle(title)
            .navigationBarItems(
                leading: Button("Annuler") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Valider") {
                    dateString = dateFormatter.string(from: selectedDate)
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }

}
