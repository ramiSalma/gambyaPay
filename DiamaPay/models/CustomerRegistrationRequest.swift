import Foundation

struct CustomerRegistrationRequest: Codable {
    let firstName: String
    let lastName: String
    let phone: String
    let email: String?
    let birthDate: String
    let nationality: String
    let documentCode: String
    let documentId: String?
    let gender: String
    let currencyCode: String
    let bank: String
    let branchCode: String
    let secretQ: String
    let answer: String
    let address: String
    let type: String?
    let productCode: String
    let entityId: String?
    let lastActionUser: String?
    let pin: String
    let nkinName: String?
    let nkinPhone: String?
    let srcFunds: String?
    let occupation: String?
    let estimatedIncome: String?
    let referralCode: String?
    let deviceId: String
    let isFirstLogin: Bool
    let faceId: String
    let documentImg: String
    let documentImgBack: String
}
