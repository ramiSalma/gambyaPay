import Foundation

struct FoodyResponse<T: Codable>: Codable {
    let respCode: String?
    let message: String?
    let result: T?
}

struct FoodyListingRequest: Codable {
    let phoneNumber: String
    let requestId: String
    let requestDate: String
    let entityId: String
}

struct FoodyItemsRequest: Codable {
    let phoneNumber: String
    let restaurantId: String
    let categoryId: String?
    let requestId: String
    let requestDate: String
    let entityId: String
}

struct FoodyRestaurantRequest: Codable {
    let phoneNumber: String
    let restaurantId: String
    let requestId: String
    let requestDate: String
    let entityId: String
}

struct FoodRestaurant: Codable, Identifiable {
    let restaurantId: String
    let name: String?
    let logoUrl: String?
    let status: String?
    let openFlag: String?
    let address1: String?
    let address2: String?
    let city: String?
    let minOrderAmount: String?
    var id: String { restaurantId }

    var isOpen: Bool { openFlag?.lowercased() == "y" || openFlag?.lowercased() == "true" || status?.lowercased() == "open" }
}

struct FoodItem: Codable, Identifiable {
    let itemId: String
    let categoryId: String?
    let restaurantId: String?
    let name: String?
    let description: String?
    let price: String?
    let imageUrl: String?
    let discountedPrice: String?
    let availableFlag: String?
    var id: String { itemId }

    var amount: Double { Double(discountedPrice ?? price ?? "") ?? 0 }
    var isAvailable: Bool { availableFlag == nil || availableFlag?.lowercased() == "y" || availableFlag?.lowercased() == "true" }
}

struct FoodAddress: Codable, Identifiable {
    let addressId: String
    let addressLine1: String?
    let addressLine2: String?
    let city: String?
    let countryCode: String?
    let defualtFlag: String?
    var id: String { addressId }

    var displayName: String { [addressLine1, addressLine2, city].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ") }
}

struct FoodCategory: Codable, Identifiable {
    let categoryId: String
    let restaurantId: String?
    let name: String?
    let displayOrder: String?
    var id: String { categoryId }
}

struct FoodOrder: Codable, Identifiable {
    let orderId: String
    let orderRef: String?
    let restaurantId: String?
    let totalAmount: Double?
    let deliveryFee: Double?
    let status: String?
    let paymentStatus: String?
    let createdAt: String?
    var id: String { orderId }
}

struct FoodOrderActionRequest: Codable {
    let phoneNumber: String
    let orderId: String
    let restaurantId: String
    let status: String
    let requestId: String
    let requestDate: String
    let entityId: String
}

struct FoodComplaintRequest: Codable {
    let phoneNumber: String
    let orderId: String
    let restaurantId: String
    let description: String
    let reason: String
    let complaintType: String
    let productId: String
    let bank: String
    let requestId: String
    let requestDate: String
    let entityId: String
}

struct FoodComplaintDetails: Codable {
    let complaintId: String?
    let orderId: String?
    let restaurantId: String?
    let productId: String?
    let complaintType: String?
    let description: String?
    let status: String?
    let merchantResponse: String?
    let supportResponse: String?
    let createdAt: String?
    let updatedAt: String?
}

struct FoodComplaintRecord: Codable, Identifiable {
    let complaint: FoodComplaintDetails?
    let order: FoodOrder?
    var id: String { complaint?.complaintId ?? complaint?.orderId ?? complaint?.createdAt ?? "food-complaint" }
}

struct FoodOrderLineRequest: Codable {
    let itemId: String
    let quantity: String
    let totalPrice: String
}

struct FoodOrderRequest: Codable {
    let phoneNumber: String
    let restaurantId: String
    let deliveryAddressId: String
    let itemsList: [FoodOrderLineRequest]
    let bank: String
    let requestId: String
    let requestDate: String
    let entityId: String
}

struct FoodAddAddressRequest: Codable {
    let phoneNumber: String
    let label: String
    let addressLine1: String
    let addressLine2: String
    let city: String
    let countryCode: String
    let postalCode: String
    let latitude: String
    let longitude: String
    let defaultFlag: String
    let requestId: String
    let requestDate: String
    let entityId: String
}
