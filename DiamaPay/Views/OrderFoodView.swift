import SwiftUI

struct OrderFoodView: View {
    @ObservedObject private var localization = AppLanguageStore.shared
    private let initiallyShowingHistory: Bool

    init(initiallyShowingHistory: Bool = false) {
        self.initiallyShowingHistory = initiallyShowingHistory
        _showingOrders = State(initialValue: initiallyShowingHistory)
        _showingClosedOrders = State(initialValue: false)
    }

    @Environment(\.dismiss) private var dismiss
    @State private var restaurants: [FoodRestaurant] = []
    @State private var selectedRestaurant: FoodRestaurant?
    @State private var items: [FoodItem] = []
    @State private var categories: [FoodCategory] = []
    @State private var selectedCategoryId: String?
    @State private var addresses: [FoodAddress] = []
    @State private var selectedAddress: FoodAddress?
    @State private var quantities: [String: Int] = [:]
    @State private var isLoading = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var notice: String?
    @State private var showAddressForm = false
    @State private var addressLabel = AppStrings.home
    @State private var addressLine1 = ""
    @State private var addressLine2 = ""
    @State private var addressCity = ""
    @State private var showingOrders = false
    @State private var showingClosedOrders = false
    @State private var orders: [FoodOrder] = []
    @State private var complaintOrder: FoodOrder?
    @State private var complaintDescription = ""

    private let blue = Color(hex: "174EA6")
    private var cartCount: Int { quantities.values.reduce(0, +) }
    private var cartTotal: Double {
        items.reduce(0) { $0 + $1.amount * Double(quantities[$1.id, default: 0]) }
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(spacing: 0) {
                DiamaPayHeader(
                    title: showingOrders ? AppStrings.foodHistory2 : (selectedRestaurant?.name ?? AppStrings.orderFood),
                    headerColor: blue,
                    onBackToHome: {
                        if showingOrders {
                            if initiallyShowingHistory { dismiss() }
                            else { showingOrders = false; loadInitialData() }
                        }
                        else if selectedRestaurant != nil { selectedRestaurant = nil; items = []; categories = []; quantities = [:] }
                        else { dismiss() }
                    }
                )
                if showingOrders {
                    ordersList
                } else if restaurants.isEmpty && isLoading {
                    ProgressView(AppStrings.findingRestaurants).frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let selectedRestaurant {
                    menu(for: selectedRestaurant)
                } else {
                    restaurantList
                }
                if cartCount > 0, selectedRestaurant != nil { checkoutBar }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AppBottomBar(onSponsors: {}, onQR: {}, onLimits: {}, onSettings: {})
        }
        .navigationBarHidden(true)
        .task { if showingOrders { loadOrders() } else { loadInitialData() } }
        .alert(AppStrings.orderFood2, isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button(AppStrings.ok, role: .cancel) { errorMessage = nil }
        } message: { Text(AppStrings.option(errorMessage ?? "")) }
        .alert(AppStrings.orderPlaced, isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })) {
            Button(AppStrings.done) { notice = nil; dismiss() }
        } message: { Text(AppStrings.option(notice ?? "")) }
        .sheet(isPresented: $showAddressForm) { addressForm }
        .sheet(item: $complaintOrder) { order in complaintForm(for: order) }
    }

    private var restaurantList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(AppStrings.restaurantsNearYou).font(.system(size: 22, weight: .bold)).padding(.top, 8)
                Button { showingOrders = true; showingClosedOrders = false; loadOrders() } label: {
                    HStack { Image(systemName: "bag"); Text(AppStrings.myOrders); Spacer(); Image(systemName: "chevron.right") }
                        .font(.system(size: 14, weight: .semibold)).foregroundStyle(blue).padding(14).background(blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                }.buttonStyle(.plain)
                if isLoading && restaurants.isEmpty { ProgressView().frame(maxWidth: .infinity).padding(40) }
                else if restaurants.isEmpty { emptyState(AppStrings.noRestaurantsAreAvailableRightNow, icon: "storefront") }
                ForEach(restaurants) { restaurant in
                    Button { select(restaurant) } label: {
                        HStack(spacing: 14) {
                            restaurantLogo(restaurant.logoUrl)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(restaurant.name ?? AppStrings.restaurant).font(.system(size: 16, weight: .semibold)).foregroundStyle(.primary)
                                Text([restaurant.address1, restaurant.city].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")).font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(1)
                                HStack(spacing: 5) { Circle().fill(restaurant.isOpen ? blue : .orange).frame(width: 7, height: 7); Text(restaurant.isOpen ? AppStrings.openNow : (restaurant.status ?? AppStrings.checkAvailability)).font(.system(size: 11, weight: .medium)).foregroundStyle(restaurant.isOpen ? blue : .orange) }
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(.tertiary)
                        }
                        .padding(12).background(.white, in: RoundedRectangle(cornerRadius: 16))
                    }.buttonStyle(.plain)
                }
            }.padding(18)
        }.refreshable { loadRestaurants() }
    }

    private func menu(for restaurant: FoodRestaurant) -> some View {
        VStack(spacing: 0) {
            if isLoading && items.isEmpty { ProgressView(AppStrings.loadingMenu).frame(maxWidth: .infinity, maxHeight: .infinity) }
            else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) { Text(restaurant.name ?? AppStrings.menu).font(.system(size: 21, weight: .bold)); Text(restaurant.city ?? restaurant.address1 ?? AppStrings.menu).font(.system(size: 12)).foregroundStyle(.secondary) }
                            Spacer()
                            Text(AppStrings.valueItems(String(describing: items.count))).font(.system(size: 12, weight: .medium)).foregroundStyle(blue).padding(.horizontal, 11).padding(.vertical, 7).background(blue.opacity(0.1), in: Capsule())
                        }.padding(.vertical, 6)
                        if !categories.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    categoryChip(AppStrings.all, id: nil)
                                    ForEach(categories) { category in categoryChip(category.name ?? AppStrings.menu, id: category.categoryId) }
                                }
                            }
                        }
                        if items.isEmpty { emptyState(AppStrings.thisRestaurantHasNoMenuItemsAvailable, icon: "takeoutbag.and.cup.and.straw") }
                        ForEach(items) { item in
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(item.name ?? AppStrings.menuItem).font(.system(size: 15, weight: .semibold))
                                    if let description = item.description, !description.isEmpty { Text(description).font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(2) }
                                    Text(String(format: "GMD %.2f", item.amount)).font(.system(size: 13, weight: .semibold)).foregroundStyle(blue).padding(.top, 2)
                                }
                                Spacer(minLength: 4)
                                if quantities[item.id, default: 0] == 0 {
                                    Button { quantities[item.id] = 1 } label: { Image(systemName: "plus").font(.system(size: 14, weight: .bold)).foregroundStyle(.white).frame(width: 34, height: 34).background(blue, in: Circle()) }
                                        .disabled(!item.isAvailable)
                                } else {
                                    HStack(spacing: 12) {
                                        Button { change(item, by: -1) } label: { Image(systemName: "minus").foregroundStyle(blue) }
                                        Text("\(quantities[item.id, default: 0])").font(.system(size: 14, weight: .semibold)).monospacedDigit()
                                        Button { change(item, by: 1) } label: { Image(systemName: "plus").foregroundStyle(blue) }
                                    }.font(.system(size: 13, weight: .bold)).padding(.horizontal, 10).padding(.vertical, 8).background(blue.opacity(0.09), in: Capsule())
                                }
                            }.padding(14).background(.white, in: RoundedRectangle(cornerRadius: 15))
                        }
                    }.padding(18)
                }.refreshable { loadItems(restaurant) }
            }
        }
    }

    private var checkoutBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "mappin.and.ellipse").foregroundStyle(blue)
                VStack(alignment: .leading, spacing: 2) { Text(AppStrings.deliverTo).font(.system(size: 10)).foregroundStyle(.secondary); Text(selectedAddress?.displayName.isEmpty == false ? selectedAddress!.displayName : AppStrings.chooseDeliveryAddress).font(.system(size: 12, weight: .medium)).foregroundStyle(.primary).lineLimit(1) }
                Spacer()
                if addresses.isEmpty {
                    Button(AppStrings.addAddress) { showAddressForm = true }.font(.system(size: 12, weight: .semibold)).foregroundStyle(blue)
                } else {
                    Menu {
                        ForEach(addresses) { address in Button(address.displayName.isEmpty ? AppStrings.deliveryAddress : address.displayName) { selectedAddress = address } }
                        Button { showAddressForm = true } label: { Label(AppStrings.addNewAddress, systemImage: "plus") }
                    } label: { Image(systemName: "chevron.up.chevron.down").font(.system(size: 10, weight: .semibold)).foregroundStyle(.secondary) }
                }
            }.padding(10).background(Color(.systemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
            Button(action: submitOrder) {
                HStack {
                    Text(isSubmitting ? AppStrings.placingOrder : AppStrings.placeOrderGmdValue(String(describing: String(format: "%.2f", cartTotal)))).font(.system(size: 15, weight: .semibold))
                    Spacer(); if isSubmitting { ProgressView().tint(.white) } else { Text(AppStrings.valueItems(String(describing: cartCount))).font(.system(size: 12, weight: .medium)).opacity(0.85) }
                }.foregroundStyle(.white).padding(.horizontal, 16).frame(height: 50).background(blue, in: RoundedRectangle(cornerRadius: 14))
            }.disabled(isSubmitting || selectedAddress == nil || cartCount == 0)
        }.padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 12).background(.white.shadow(.drop(color: .black.opacity(0.07), radius: 8, y: -3)))
    }

    private func restaurantLogo(_ urlString: String?) -> some View {
        Group {
            if let urlString, let url = URL(string: urlString) { AsyncImage(url: url) { image in image.resizable().scaledToFill() } placeholder: { logoPlaceholder }.frame(width: 64, height: 64).clipShape(RoundedRectangle(cornerRadius: 13)) }
            else { logoPlaceholder.frame(width: 64, height: 64).clipShape(RoundedRectangle(cornerRadius: 13)) }
        }
    }
    private var logoPlaceholder: some View { Image(systemName: "takeoutbag.and.cup.and.straw.fill").font(.system(size: 24)).foregroundStyle(blue).frame(maxWidth: .infinity, maxHeight: .infinity).background(blue.opacity(0.1)) }
    private var addressForm: some View {
        NavigationStack {
            Form {
                TextField(AppStrings.labelHomeWork, text: $addressLabel)
                TextField(AppStrings.streetAddress, text: $addressLine1)
                TextField(AppStrings.apartmentSuiteOptional, text: $addressLine2)
                TextField(AppStrings.city, text: $addressCity)
            }
            .navigationTitle(AppStrings.deliveryAddress)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(AppStrings.cancel) { showAddressForm = false } }
                ToolbarItem(placement: .confirmationAction) { Button(AppStrings.save) { saveAddress() }.disabled(addressLine1.trimmingCharacters(in: .whitespaces).isEmpty || addressCity.trimmingCharacters(in: .whitespaces).isEmpty) }
            }
        }
        .presentationDetents([.medium, .large])
    }
    private func emptyState(_ text: String, icon: String) -> some View {
        VStack(spacing: 10) { Image(systemName: icon).font(.system(size: 30)).foregroundStyle(blue.opacity(0.7)); Text(text).font(.system(size: 14)).foregroundStyle(.secondary).multilineTextAlignment(.center) }.frame(maxWidth: .infinity).padding(30).background(.white, in: RoundedRectangle(cornerRadius: 16))
    }

    private var ordersList: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                orderTab(AppStrings.active, active: !showingClosedOrders) { showingClosedOrders = false; loadOrders() }
                orderTab(AppStrings.past, active: showingClosedOrders) { showingClosedOrders = true; loadOrders() }
            }.padding(.horizontal, 18).padding(.vertical, 12)
            if isLoading { ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity) }
            else if orders.isEmpty { emptyState(AppStrings.yourOrdersWillAppearHere, icon: "bag").padding(18); Spacer() }
            else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(orders) { order in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) { Text(AppStrings.orderValue(String(describing: order.orderRef ?? order.orderId))).font(.system(size: 15, weight: .semibold)); Text(order.createdAt ?? "").font(.system(size: 11)).foregroundStyle(.secondary) }
                                    Spacer(); Text(AppStrings.option(order.status ?? "ORDERED")).font(.system(size: 10, weight: .bold)).foregroundStyle(blue).padding(.horizontal, 9).padding(.vertical, 6).background(blue.opacity(0.1), in: Capsule())
                                }
                                HStack { Text("GMD \(String(format: "%.2f", order.totalAmount ?? 0))").font(.system(size: 13, weight: .semibold)); Spacer()
                                    if !showingClosedOrders && ["CREATED", "CONFIRMED"].contains(order.status?.uppercased() ?? "") { Button(AppStrings.cancel) { cancel(order) }.font(.system(size: 12, weight: .semibold)).foregroundStyle(.red) }
                                    Button(AppStrings.getHelp) { complaintDescription = ""; complaintOrder = order }.font(.system(size: 12, weight: .semibold)).foregroundStyle(blue)
                                }
                            }.padding(14).background(.white, in: RoundedRectangle(cornerRadius: 15))
                        }
                    }.padding(18)
                }
            }
        }
    }

    private func orderTab(_ title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) { Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(active ? .white : .primary).frame(maxWidth: .infinity).padding(.vertical, 10).background(active ? blue : .white, in: Capsule()) }.buttonStyle(.plain)
    }

    private func categoryChip(_ title: String, id: String?) -> some View {
        Button { selectedCategoryId = id; if let selectedRestaurant { loadItems(selectedRestaurant) } } label: {
            Text(title).font(.system(size: 12, weight: .semibold)).foregroundStyle(selectedCategoryId == id ? .white : blue).padding(.horizontal, 14).padding(.vertical, 8).background(selectedCategoryId == id ? blue : blue.opacity(0.1), in: Capsule())
        }.buttonStyle(.plain)
    }

    private func complaintForm(for order: FoodOrder) -> some View {
        NavigationStack {
            Form { Section(AppStrings.orderValue(String(describing: order.orderRef ?? order.orderId))) { TextField(AppStrings.tellUsWhatHappened, text: $complaintDescription, axis: .vertical).lineLimit(4...7) } }
                .navigationTitle(AppStrings.contactSupport).navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button(AppStrings.cancel) { complaintOrder = nil } }
                    ToolbarItem(placement: .confirmationAction) { Button(AppStrings.send) { sendComplaint(for: order) }.disabled(complaintDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
                }
        }.presentationDetents([.medium, .large])
    }

    private func loadInitialData() {
        isLoading = true
        APIClient.shared.listFoodRestaurants(request: makeListingRequest()) { result in
            Task { @MainActor in
                isLoading = false
                switch result {
                case .success(let response): restaurants = response.result ?? []; if response.respCode != "000" { errorMessage = response.message ?? AppStrings.couldNotLoadRestaurants }
                case .failure(let error): errorMessage = error.localizedDescription
                }
            }
        }
        APIClient.shared.listFoodAddresses(request: makeListingRequest()) { result in
            Task { @MainActor in
                if case .success(let response) = result {
                    addresses = response.result ?? []
                    selectedAddress = addresses.first(where: { $0.defualtFlag?.lowercased() == "y" || $0.defualtFlag?.lowercased() == "true" }) ?? addresses.first
                }
            }
        }
    }

    private func loadRestaurants() {
        isLoading = true
        APIClient.shared.listFoodRestaurants(request: makeListingRequest()) { result in
            Task { @MainActor in isLoading = false; if case .success(let response) = result { restaurants = response.result ?? [] } else if case .failure(let error) = result { errorMessage = error.localizedDescription } }
        }
    }

    private func select(_ restaurant: FoodRestaurant) {
        selectedRestaurant = restaurant
        selectedCategoryId = nil
        quantities = [:]
        loadCategories(restaurant)
        loadItems(restaurant)
    }

    private func loadItems(_ restaurant: FoodRestaurant) {
        isLoading = true
        let base = makeListingRequest()
        let request = FoodyItemsRequest(phoneNumber: base.phoneNumber, restaurantId: restaurant.restaurantId, categoryId: selectedCategoryId, requestId: base.requestId, requestDate: base.requestDate, entityId: base.entityId)
        APIClient.shared.listFoodItems(request: request) { result in
            Task { @MainActor in isLoading = false; switch result { case .success(let response): items = response.result ?? []; if response.respCode != "000" { errorMessage = response.message ?? AppStrings.couldNotLoadTheMenu }; case .failure(let error): errorMessage = error.localizedDescription } }
        }
    }

    private func loadCategories(_ restaurant: FoodRestaurant) {
        let base = makeListingRequest()
        let request = FoodyRestaurantRequest(phoneNumber: base.phoneNumber, restaurantId: restaurant.restaurantId, requestId: base.requestId, requestDate: base.requestDate, entityId: base.entityId)
        APIClient.shared.listFoodCategories(request: request) { result in
            Task { @MainActor in if case .success(let response) = result { categories = response.result ?? [] } }
        }
    }

    private func loadOrders() {
        isLoading = true
        let request = makeListingRequest()
        let completion: (Result<FoodyResponse<[FoodOrder]>, Error>) -> Void = { result in
            Task { @MainActor in isLoading = false; switch result { case .success(let response): orders = response.result ?? []; if response.respCode != "000" { errorMessage = response.message }; case .failure(let error): errorMessage = error.localizedDescription } }
        }
        if showingClosedOrders { APIClient.shared.listClosedFoodOrders(request: request, completion: completion) }
        else { APIClient.shared.listActiveFoodOrders(request: request, completion: completion) }
    }

    private func cancel(_ order: FoodOrder) {
        guard let restaurantId = order.restaurantId else { return }
        let base = makeListingRequest()
        let request = FoodOrderActionRequest(phoneNumber: base.phoneNumber, orderId: order.orderId, restaurantId: restaurantId, status: "CANCELLED", requestId: base.requestId, requestDate: base.requestDate, entityId: base.entityId)
        APIClient.shared.cancelFoodOrder(request: request) { result in
            Task { @MainActor in switch result { case .success(let response) where response.respCode == "000": loadOrders(); case .success(let response): errorMessage = response.message ?? AppStrings.couldNotCancelThisOrder; case .failure(let error): errorMessage = error.localizedDescription } }
        }
    }

    private func sendComplaint(for order: FoodOrder) {
        guard let restaurantId = order.restaurantId else { return }
        let base = makeListingRequest()
        let request = FoodComplaintRequest(phoneNumber: base.phoneNumber, orderId: order.orderId, restaurantId: restaurantId, description: complaintDescription, reason: "CUSTOMER_SUPPORT", complaintType: "ORDER", productId: "", bank: UserDataManager.shared.getBankCode(), requestId: base.requestId, requestDate: base.requestDate, entityId: base.entityId)
        APIClient.shared.addFoodComplaint(request: request) { result in
            Task { @MainActor in switch result { case .success(let response) where response.respCode == "000": complaintOrder = nil; notice = response.message ?? AppStrings.yourMessageHasBeenSent; case .success(let response): errorMessage = response.message ?? AppStrings.couldNotSendYourMessage; case .failure(let error): errorMessage = error.localizedDescription } }
        }
    }

    private func change(_ item: FoodItem, by amount: Int) {
        let next = quantities[item.id, default: 0] + amount
        if next <= 0 { quantities.removeValue(forKey: item.id) } else { quantities[item.id] = next }
    }

    private func submitOrder() {
        guard let restaurant = selectedRestaurant, let address = selectedAddress else { return }
        isSubmitting = true
        let base = makeListingRequest()
        let lines = items.compactMap { item -> FoodOrderLineRequest? in
            let quantity = quantities[item.id, default: 0]
            guard quantity > 0 else { return nil }
            return FoodOrderLineRequest(itemId: item.itemId, quantity: String(quantity), totalPrice: String(format: "%.2f", item.amount * Double(quantity)))
        }
        let request = FoodOrderRequest(phoneNumber: base.phoneNumber, restaurantId: restaurant.restaurantId, deliveryAddressId: address.addressId, itemsList: lines, bank: UserDataManager.shared.getBankCode(), requestId: base.requestId, requestDate: base.requestDate, entityId: base.entityId)
        APIClient.shared.placeFoodOrder(request: request) { result in
            Task { @MainActor in
                isSubmitting = false
                switch result {
                case .success(let response) where response.respCode == "000": notice = response.message ?? AppStrings.yourOrderHasBeenReceived
                case .success(let response): errorMessage = response.message ?? AppStrings.couldNotPlaceYourOrder
                case .failure(let error): errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func saveAddress() {
        let base = makeListingRequest()
        let request = FoodAddAddressRequest(phoneNumber: base.phoneNumber, label: addressLabel, addressLine1: addressLine1, addressLine2: addressLine2, city: addressCity, countryCode: "GM", postalCode: "", latitude: "", longitude: "", defaultFlag: addresses.isEmpty ? "Y" : "N", requestId: base.requestId, requestDate: base.requestDate, entityId: base.entityId)
        APIClient.shared.addFoodAddress(request: request) { result in
            Task { @MainActor in
                switch result {
                case .success(let response) where response.respCode == "000":
                    showAddressForm = false
                    addressLine1 = ""; addressLine2 = ""; addressCity = ""
                    refreshAddresses()
                case .success(let response): errorMessage = response.message ?? AppStrings.couldNotSaveThisAddress
                case .failure(let error): errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func refreshAddresses() {
        APIClient.shared.listFoodAddresses(request: makeListingRequest()) { result in
            Task { @MainActor in
                if case .success(let response) = result {
                    addresses = response.result ?? []
                    selectedAddress = addresses.first(where: { $0.defualtFlag?.lowercased() == "y" || $0.defualtFlag?.lowercased() == "true" }) ?? addresses.last
                }
            }
        }
    }

    private func makeListingRequest() -> FoodyListingRequest {
        let formatter = DateFormatter.with(format: "yyyy-MM-dd HH:mm:ss")
        let date = Date()
        return FoodyListingRequest(phoneNumber: UserDataManager.shared.getPhoneNumber(), requestId: DateFormatter.with(format: "yyMMdd").string(from: date) + String(format: "%06d", Int.random(in: 0..<1_000_000)), requestDate: formatter.string(from: date), entityId: "SYSTEM")
    }
}
