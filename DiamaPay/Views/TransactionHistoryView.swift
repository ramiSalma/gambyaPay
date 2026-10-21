import SwiftUI
import UIKit

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
    @State private var showExportSheet = false
    @State private var exportedFileURL: URL?
    
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
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                historyHeader

                if isLoading {
                    Spacer()
                    VStack(spacing: 14) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blueH))
                            .scaleEffect(1.5)
                        
                        Text("Loading transactions...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    // Content
                    ScrollView {
                        VStack(spacing: 14) {
                            // Filter section
                            filterSection
                            
                            // Transactions section
                            transactionsSection

                            if !transactions.isEmpty {
                                // Pagination
                                if totalPages > 1 {
                                    paginationSection
                                }
                            } else if !isLoading {
                                emptyStateView
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 16)
                    }
                }
            }
        }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AppBottomBar(onSponsors: {}, onQR: {}, onLimits: {}, onSettings: {})
        }
        .navigationBarHidden(true)
        .onAppear {
            setDefaultDateRange()
            loadLast30DaysTransactions()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Something went wrong.")
        }
        .sheet(isPresented: $showStartDatePicker) {
            DatePickerSheet(
                selectedDate: $selectedStartDate,
                dateString: $startDate,
                title: "Start date"
            )
        }
        .sheet(isPresented: $showEndDatePicker) {
            DatePickerSheet(
                selectedDate: $selectedEndDate,
                dateString: $endDate,
                title: "End date"
            )
        }
        .sheet(isPresented: $showExportSheet) {
            if let exportedFileURL {
                ActivityViewController(activityItems: [exportedFileURL])
            }
        }
    }
    
   
    
    private var historyHeader: some View {
        HStack {
            Button { presentationMode.wrappedValue.dismiss() } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
            }
            Spacer()
            Text("Transaction History")
                .font(.system(size: 19, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 14)
        .frame(height: 54)
        .background(Color(hex: "174EA6").ignoresSafeArea(edges: .top))
    }

    // MARK: - Filter Section
    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Filter by Date")

            HStack(spacing: 12) {
                dateInput(title: "Start Date", value: startDate) { showStartDatePicker = true }
                dateInput(title: "End Date", value: endDate) { showEndDatePicker = true }
            }

            HStack(spacing: 12) {
                Button(action: resetFilters) {
                    Text("Reset")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(hex: "174EA6"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                Button(action: filterTransactions) {
                    Text("Filter")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(hex: "174EA6"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.12), radius: 7, x: 0, y: 3)
    }

    private func dateInput(title: String, value: String, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "505A69"))
            Button(action: action) {
                HStack(spacing: 6) {
                    Text(value)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "858585"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 2)
                    Image(systemName: "calendar")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "0788B9"))
                }
                .padding(.horizontal, 11)
                .frame(height: 48)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 11))
                .overlay(RoundedRectangle(cornerRadius: 11).stroke(Color(hex: "596273"), lineWidth: 1.2))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionTitle(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(hex: "174EA6"))
            Rectangle()
                .fill(Color(hex: "0788B9"))
                .frame(width: 76, height: 2)
        }
    }
    
    // MARK: - Transactions Section
    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    sectionTitle("Last 30 Days")
                }
                Spacer(minLength: 8)
                exportMenu
            }

            VStack(spacing: 0) {
                ForEach(transactions.indices, id: \.self) { index in
                    transactionRow(transactions[index])
                    if index < transactions.count - 1 {
                        Rectangle()
                            .fill(Color.gray.opacity(0.22))
                            .frame(height: 1)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.12), radius: 7, x: 0, y: 3)
    }

    private var exportMenu: some View {
        Menu {
            Button { exportTransactions(as: .pdf) } label: {
                Label("PDF", systemImage: "doc.richtext")
            }
            Button { exportTransactions(as: .excel) } label: {
                Label("Excel", systemImage: "tablecells")
            }
            Button { exportTransactions(as: .csv) } label: {
                Label("CSV", systemImage: "doc.text")
            }
        } label: {
            Image(systemName: "arrow.down.to.line")
                .font(.system(size: 19, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(Color(hex: "174EA6"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .accessibilityLabel("Export transactions")
    }
 
    private func transactionRow(_ transaction: Transaction) -> some View {
        NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
            HStack(alignment: .center, spacing: 8) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(transaction.date)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "505A69"))
                        
                        Text(transaction.title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        Text(transaction.reference)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "252525"))

                        Text(transaction.balance)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "717171"))
                    }
                    
                    Spacer(minLength: 4)
                    
                    Text(transaction.amount)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(hex: "174EA6"))
                        .multilineTextAlignment(.trailing)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle()) // remove default blue highlight
    }

    private enum ExportFormat: Equatable {
        case pdf
        case excel
        case csv
    }

    private func exportTransactions(as format: ExportFormat) {
        let fileName: String
        let fileData: Data
        switch format {
        case .pdf:
            fileName = "Transaction_History.pdf"
            fileData = makeTransactionsPDF()
        case .excel, .csv:
            fileName = format == .excel ? "Transaction_History_Excel.csv" : "Transaction_History.csv"
            let rows = ["Date,Type,Reference,Amount,Balance,Status,Details"] + filteredTransactions.map { transaction in
                [transaction.date, transaction.title, transaction.reference, transaction.amount,
                 transaction.balance, transaction.status ?? "", transaction.details ?? ""]
                    .map(csvEscaped)
                    .joined(separator: ",")
            }
            fileData = rows.joined(separator: "\n").data(using: .utf8) ?? Data()
        }

        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try fileData.write(to: fileURL, options: .atomic)
            exportedFileURL = fileURL
            showExportSheet = true
        } catch {
            showErrorMessage("Unable to create the export file. Please try again.")
        }
    }

    private func csvEscaped(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    private func makeTransactionsPDF() -> Data {
        let bounds = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds)
        return renderer.pdfData { context in
            var y: CGFloat = 48
            let left: CGFloat = 40
            let bodyFont = UIFont.systemFont(ofSize: 11)
            let titleFont = UIFont.boldSystemFont(ofSize: 18)
            let textColor = UIColor(Color(hex: "172B4D"))

            context.beginPage()
            "Transaction History".draw(at: CGPoint(x: left, y: y), withAttributes: [.font: titleFont, .foregroundColor: UIColor(Color(hex: "174EA6"))])
            y += 32
            "Date range: \(startDate) - \(endDate)".draw(at: CGPoint(x: left, y: y), withAttributes: [.font: bodyFont, .foregroundColor: textColor])
            y += 28

            for transaction in filteredTransactions {
                if y > bounds.height - 92 {
                    context.beginPage()
                    y = 48
                }
                let lines = [transaction.date, transaction.title, transaction.reference,
                             transaction.amount, transaction.balance, transaction.status ?? ""]
                for line in lines where !line.isEmpty {
                    line.draw(at: CGPoint(x: left, y: y), withAttributes: [.font: bodyFont, .foregroundColor: textColor])
                    y += 16
                }
                y += 8
            }
        }
    }

    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
        .font(.system(size: 38))
                .foregroundColor(.gray)
            
            Text("No transactions found")
                .font(.system(size: 18))
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("There are no transactions for the selected date range.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Refresh") {
                loadLast30DaysTransactions()
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color(hex: "174EA6"))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(40)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.black.opacity(0.05), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.08), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Pagination Section
    private var paginationSection: some View {
        VStack(spacing: 12) {
            // Page info
            Text("Page \(currentPage) of \(totalPages)")
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
            showErrorMessage("Wallet number not found. Please sign in again.")
            return
        }
        
        isLoading = true
        
        var request = RequestEStatement(walletNumber: walletNumber, pin: pin)
        let user = UserDataManager.shared
        request.phoneNumber = user.getPhoneNumber()
        request.source = "W"
        request.bank = user.getBankCode().isEmpty ? "00100" : user.getBankCode()
        request.dateFrom = historyRequestDateFormatter.string(from: selectedStartDate)
        request.dateTo = historyRequestDateFormatter.string(from: selectedEndDate)
        request.type = "P"
        request.entityId = user.getUserCode()

        print("[TransactionHistory] POST last 30 days request: source=\(request.source), bank=\(request.bank), dateFrom=\(request.dateFrom), dateTo=\(request.dateTo)")
        
        APIClient.shared.getLast30DaysTransactions(request: request) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    print("[TransactionHistory] Response: respCode=\(response.respCode ?? "nil"), status=\(response.status ?? "nil"), resultCount=\(response.result?.count ?? 0), hasResult=\(response.result != nil)")
                    if response.isSuccessful {
                        self.processTransactionsResponse(response)
                    } else {
                        print("[TransactionHistory] Request failed: \(response.message ?? "no message")")
                        self.showErrorMessage("Unable to load transactions. \(response.message ?? "Please try again.")")
                    }
                    
                case .failure(let error):
                    if let apiError = error as? APIError {
                        print("[TransactionHistory] API error: code=\(apiError.respCode ?? "nil"), message=\(apiError.message)")
                        self.showErrorMessage("Error: \(apiError.message)")
                    } else {
                        print("[TransactionHistory] Request error: \(error.localizedDescription)")
                        self.showErrorMessage("Connection error: \(error.localizedDescription)")
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
            print("[TransactionHistory] Successful response contained no transaction rows.")
            allTransactions = []
            filteredTransactions = []
            transactions = []
            loadFirstPage()
            return
        }
        
        // Convert API results to Transaction objects
        for result in results {
            let transaction = Transaction(from: result)
            allTransactions.append(transaction)
        }
        
        print("[TransactionHistory] Parsed \(allTransactions.count) transaction rows; displaying all rows returned for the requested date range.")

        // The history endpoint applies dateFrom/dateTo. Keep every returned row instead
        // of filtering again with a client-side date parser that can reject valid dates.
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
            showErrorMessage("Please select a start and end date.")
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "dd/MM/yyyy"
        guard let fromDate = dateFormatter.date(from: startDate),
              let toDate = dateFormatter.date(from: endDate), fromDate <= toDate else {
            showErrorMessage("The start date must be on or before the end date.")
            return
        }

        // Fetch the chosen interval from the backend so dates outside the initial 30-day
        // window can be searched as well.
        loadLast30DaysTransactions()
    }
    
    private func resetFilters() {
        setDefaultDateRange()
        loadLast30DaysTransactions()
        // Reset to the default 30-day range.
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

    private let historyRequestDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
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
        formatter.locale = Locale(identifier: "en_US_POSIX")
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
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Done") {
                    dateString = dateFormatter.string(from: selectedDate)
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }

}
