import SwiftUI

struct FoodComplaintsView: View {
    @ObservedObject private var localization = AppLanguageStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var complaints: [FoodComplaintRecord] = []
    @State private var orders: [FoodOrder] = []
    @State private var selectedOrder: FoodOrder?
    @State private var selectedType = AppStrings.original("foodQuality")
    @State private var description = ""
    @State private var isLoading = true
    @State private var isSubmitting = false
    @State private var showForm = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    private let blue = Color(hex: "174EA6")
    private let complaintTypes = [AppStrings.original("foodQuality"), AppStrings.original("missingItem"), AppStrings.original("lateDelivery"), AppStrings.original("incorrectOrder"), AppStrings.original("restaurantService"), AppStrings.original("other")]

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(spacing: 0) {
                DiamaPayHeader(title: AppStrings.foodComplaints, headerColor: blue)
                if isLoading {
                    Spacer()
                    ProgressView().tint(blue)
                    Text(AppStrings.loadingComplaints).font(.system(size: 14)).foregroundStyle(.secondary).padding(.top, 10)
                    Spacer()
                } else if complaints.isEmpty {
                    ScrollView {
                        VStack(spacing: 14) {
                            emptyState
                            fileComplaintEntry
                        }.padding(20)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            fileComplaintEntry
                            ForEach(complaints) { record in complaintCard(record) }
                        }.padding(18)
                    }.refreshable { loadComplaints() }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AppBottomBar(onSponsors: {}, onQR: {}, onLimits: {}, onSettings: {})
        }
        .navigationBarHidden(true)
        .task { loadData() }
        .sheet(isPresented: $showForm) { complaintForm }
        .alert(AppStrings.foodComplaints2, isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button(AppStrings.ok, role: .cancel) { errorMessage = nil }
        } message: { Text(AppStrings.option(errorMessage ?? "")) }
        .alert(AppStrings.complaintSubmitted, isPresented: Binding(get: { successMessage != nil }, set: { if !$0 { successMessage = nil } })) {
            Button(AppStrings.done) { successMessage = nil }
        } message: { Text(AppStrings.option(successMessage ?? "")) }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.exclamationmark.bubble.right").font(.system(size: 34)).foregroundStyle(blue)
            Text(AppStrings.noFoodComplaintsYet).font(.system(size: 18, weight: .semibold))
            Text(AppStrings.ifSomethingWentWrongWithAFoodOrderTellUs).font(.system(size: 14)).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(28).background(Color(.systemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }

    private var fileComplaintEntry: some View {
        VStack(spacing: 8) {
            Button { showForm = true } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill").font(.system(size: 20))
                    Text(AppStrings.fileAFoodServiceComplaint).font(.system(size: 15, weight: .semibold))
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(.white).padding(16).background(blue, in: RoundedRectangle(cornerRadius: 15))
            }
            .buttonStyle(.plain).disabled(orders.isEmpty)
            if orders.isEmpty {
                Text(AppStrings.placeAFoodOrderFirstToFileAComplaintAbout).font(.system(size: 12)).foregroundStyle(.secondary)
            }
        }
    }

    private func complaintCard(_ record: FoodComplaintRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(record.complaint?.complaintType ?? AppStrings.foodService).font(.system(size: 15, weight: .semibold))
                Spacer()
                Text(AppStrings.option(record.complaint?.status ?? "SUBMITTED"))
                    .font(.system(size: 10, weight: .bold)).foregroundStyle(blue).padding(.horizontal, 9).padding(.vertical, 6).background(blue.opacity(0.1), in: Capsule())
            }
            if let orderRef = record.order?.orderRef ?? record.complaint?.orderId {
                Label(AppStrings.orderValue(String(describing: orderRef)), systemImage: "bag").font(.system(size: 12)).foregroundStyle(.secondary)
            }
            if let text = record.complaint?.description, !text.isEmpty { Text(text).font(.system(size: 14)).foregroundStyle(.primary) }
            if let response = record.complaint?.supportResponse ?? record.complaint?.merchantResponse, !response.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(AppStrings.response).font(.system(size: 11, weight: .semibold)).foregroundStyle(blue)
                    Text(response).font(.system(size: 13)).foregroundStyle(.secondary)
                }.frame(maxWidth: .infinity, alignment: .leading).padding(11).background(blue.opacity(0.06), in: RoundedRectangle(cornerRadius: 11))
            }
            if let createdAt = record.complaint?.createdAt, !createdAt.isEmpty { Text(createdAt).font(.system(size: 11)).foregroundStyle(.tertiary) }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading).background(Color(.systemGroupedBackground), in: RoundedRectangle(cornerRadius: 15))
    }

    private var complaintForm: some View {
        NavigationStack {
            Form {
                Section(AppStrings.order) {
                    Menu {
                        ForEach(orders) { order in
                            Button(AppStrings.valueValue2(String(describing: order.orderRef ?? order.orderId), String(describing: order.status ?? AppStrings.order))) { selectedOrder = order }
                        }
                    } label: {
                        HStack { Text(selectedOrder.map { $0.orderRef ?? $0.orderId } ?? AppStrings.selectAnOrder); Spacer(); Image(systemName: "chevron.up.chevron.down").foregroundStyle(.secondary) }
                    }
                }
                Section(AppStrings.whatWentWrong) {
                    Picker(AppStrings.complaintType, selection: $selectedType) {
                        ForEach(complaintTypes, id: \.self) { Text(AppStrings.option($0)).tag($0) }
                    }
                    TextField(AppStrings.describeTheIssue, text: $description, axis: .vertical).lineLimit(4...8)
                }
            }
            .navigationTitle(AppStrings.newComplaint)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(AppStrings.cancel) { showForm = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSubmitting ? AppStrings.sending : AppStrings.submit) { submitComplaint() }
                        .disabled(isSubmitting || selectedOrder == nil || description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func loadData() {
        loadComplaints()
        let request = makeRequest()
        APIClient.shared.listActiveFoodOrders(request: request) { result in
            let activeOrders: [FoodOrder]
            if case .success(let response) = result { activeOrders = response.result ?? [] } else { activeOrders = [] }
            APIClient.shared.listClosedFoodOrders(request: self.makeRequest()) { closedResult in
                let closedOrders: [FoodOrder]
                if case .success(let response) = closedResult { closedOrders = response.result ?? [] } else { closedOrders = [] }
                DispatchQueue.main.async {
                    let uniqueOrders = Dictionary((activeOrders + closedOrders).map { ($0.orderId, $0) }, uniquingKeysWith: { first, _ in first })
                    self.orders = Array(uniqueOrders.values).sorted { ($0.createdAt ?? "") > ($1.createdAt ?? "") }
                    self.selectedOrder = self.orders.first
                }
            }
        }
    }

    private func loadComplaints() {
        isLoading = true
        APIClient.shared.listFoodComplaints(request: makeRequest()) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let response):
                    complaints = response.result ?? []
                    if response.respCode != "000" { errorMessage = response.message ?? AppStrings.couldNotLoadFoodComplaints }
                case .failure(let error): errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func submitComplaint() {
        guard let order = selectedOrder, let restaurantId = order.restaurantId else { return }
        isSubmitting = true
        let base = makeRequest()
        let request = FoodComplaintRequest(
            phoneNumber: base.phoneNumber,
            orderId: order.orderId,
            restaurantId: restaurantId,
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            reason: selectedType,
            complaintType: selectedType,
            productId: "",
            bank: UserDataManager.shared.getBankCode(),
            requestId: base.requestId,
            requestDate: base.requestDate,
            entityId: base.entityId
        )
        APIClient.shared.addFoodComplaint(request: request) { result in
            DispatchQueue.main.async {
                isSubmitting = false
                switch result {
                case .success(let response) where response.respCode == "000":
                    showForm = false
                    description = ""
                    successMessage = response.message ?? AppStrings.yourComplaintHasBeenSubmitted
                    loadComplaints()
                case .success(let response): errorMessage = response.message ?? AppStrings.couldNotSubmitYourComplaint
                case .failure(let error): errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func makeRequest() -> FoodyListingRequest {
        let now = Date()
        return FoodyListingRequest(
            phoneNumber: UserDataManager.shared.getPhoneNumber(),
            requestId: DateFormatter.with(format: "yyMMdd").string(from: now) + String(format: "%06d", Int.random(in: 0..<1_000_000)),
            requestDate: DateFormatter.with(format: "yyyy-MM-dd HH:mm:ss").string(from: now),
            entityId: "SYSTEM"
        )
    }
}
