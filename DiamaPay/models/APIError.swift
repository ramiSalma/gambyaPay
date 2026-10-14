//
//  APIError.swift
//  DiamaPay
//
//  Created by Bits on 17/9/2025.
//


struct APIError: Codable, Error {
    let success: Bool
    let message: String
    let respCode: String?
    let details: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case message
        case respCode = "respCode"
        case details
    }
}
