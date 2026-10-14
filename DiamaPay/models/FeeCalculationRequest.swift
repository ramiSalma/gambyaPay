//
//  FeeCalculationRequest.swift
//  DiamaPay
//
//  Created by Bits on 28/9/2025.
//




struct FeeCalculationRequest: Codable {
    var processingCode: String = ""
    var bankCode: String = ""
    var actionCode: String = ""
    var currencyCode: String = ""
    var transactionAmount: Double = 0.0
    var walletProductCode: String = ""
    var walletType: String = ""
    var origin: String = ""
    var messageType: String = "ON_US"
}
