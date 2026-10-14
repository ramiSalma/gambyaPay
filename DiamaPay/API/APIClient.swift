import Foundation
import UIKit

class APIClient {
    static let shared = APIClient()

   // private let baseURL = "https://129.151.250.184:8080/DiamaBankWalletF/"
   private let baseURL = "http://129.151.250.184:8080/DiamaBankWalletF/"
    //private let baseURL = "https://129.151.250.184:8443/DiamaBankWalletF/"
    //private let baseURL = "https://api2.diamabank.com:8444/DiamaBankWalletF/"


    private var session = URLSession.shared
    private var userDataManager: UserDataManager?
    
    private let defaultTimeout: TimeInterval = 60.0
    private let uploadTimeout: TimeInterval = 120.0
    
    
    private static func buildUserAgent() -> String {
          let appName = "DiamaCash"
            let osType = "iOS"
    
            let versionName = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
            let versionCode = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
            return "\(appName) OS=[\(osType)] VERSION_NAME=[\(versionName)] VERSION_CODE=[\(versionCode)]"
        }
    
    private init() {
        let configuration = URLSessionConfiguration.default
           configuration.httpAdditionalHeaders = [
            "User-Agent": Self.buildUserAgent()
           ]
        configuration.timeoutIntervalForRequest = defaultTimeout
              configuration.timeoutIntervalForResource = defaultTimeout * 2
              
        
           self.session = URLSession(configuration: configuration)
       
        
    }
    

        func calculateWithdrawalFee(
            request: FeeCalculationRequest,
            completion: @escaping (Result<FeeCalculationSimpleResponse, Error>) -> Void
        ) {
            let endpoint = "api/fees/calculate"
        
            
            performRequest(
                endpoint: endpoint,
                method: .POST,
                body: request,
                requiresAuth: true,
                completion: completion
            )
        }
    
        func calculateTransactionFee(
            request: FeeCalculationRequest,
            completion: @escaping (Result<FeeCalculationResponse, Error>) -> Void
        ) {
            let endpoint = "api/wallet/calculate-fee"
            
    
            performRequest(
                endpoint: endpoint,
                method: .POST,
                body: request,
                requiresAuth: true,
                completion: completion
            )
        }
    
    
    private func decodeResponse<T: Codable>(_ data: Data) -> Result<T, Error> {
        do {
            let result = try JSONDecoder().decode(T.self, from: data)
            return .success(result)
        } catch {
            if let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
                return .failure(apiError)
            }
            return .failure(error)
        }
    }
    
    
    func getWalletLimits(
           request: RequestGetWalletLimits,
           completion: @escaping (Result<ResponseGetWalletLimits, Error>) -> Void
       ) {
           let endpoint = "api/wallet/limits"
           performRequest(
               endpoint: endpoint,
               method: .POST,
               body: request,
               requiresAuth: true,
               completion: completion
           )
       }
    
    func qrTransfer(request: RequestQrPayment, completion: @escaping (Result<ResponseService, Error>) -> Void) {
        let endpoint = "api/wallet/qrtransfer"
        performRequest(endpoint: endpoint, method: .POST, body: request, requiresAuth: true, completion: completion)
    }

    func getOrGenerateCustomerQR(request: GenerateCustomerQRRequest, completion: @escaping (Result<ResponseServiceJson, Error>) -> Void) {
        let endpoint = "api/wallet/qr/customer"
        performRequest(endpoint: endpoint, method: .POST, body: request, requiresAuth: true, completion: completion)
    }

    func listSecretQuestions(request: EmptyRequest, completion: @escaping (Result<JResponseService, Error>) -> Void) {
        let endpoint = "api/wallet/list-secretQ"
        performRequest(endpoint: endpoint, method: .POST, body: request, requiresAuth: false, completion: completion)
    }
    
    func getNationalities(completion: @escaping (Result<[Nationality], Error>) -> Void) {
        let endpoint = "api/nationalities"
        performRequest(endpoint: endpoint, method: .GET, body: nil as String?, requiresAuth: false, completion: completion)
    }

 
    // MARK: - Security Questions Endpoint
    func listSecurityQuestions(completion: @escaping (Result<JResponseService, Error>) -> Void) {
        let endpoint = "api/wallet/list-secretQ"
        performRequest(endpoint: endpoint, method: .POST, body: nil as String?, requiresAuth: false, completion: completion)
    }

    func verifyOtpReset(request: OtpResetVerificationRequest, completion: @escaping (Result<ForgotPinResponse, Error>) -> Void) {
        let endpoint = "api/auth/forgot-pin/verify-otp"
        performRequest(endpoint: endpoint, method: .POST, body: request, requiresAuth: false, completion: completion)
    }
       func unlinkSponsoredWallet(
           request: SponsoredWalletDto,
           completion: @escaping (Result<JResponseService, Error>) -> Void
       ) {
           let endpoint = "api/sponsor/unlink"
           performRequest(endpoint: endpoint,
                         method: .POST,
                         body: request,
                         requiresAuth: true,
                         completion: completion)
       }
       
       func updateSponsoredWallet(
           request: SponsoredWalletDto,
           completion: @escaping (Result<ResponseServiceJson, Error>) -> Void
       ) {
           let endpoint = "api/sponsor/update"
           performRequest(endpoint: endpoint,
                         method: .POST,
                         body: request,
                         requiresAuth: true,
                         completion: completion)
       }
       
       func sponsorWallet(
           request: SponsoredWalletDto,
           completion: @escaping (Result<ResponseServiceJson, Error>) -> Void
       ) {
           let endpoint = "api/sponsor/sponsor-wallet"
           performRequest(endpoint: endpoint,
                         method: .POST,
                         body: request,
                         requiresAuth: true,
                         completion: completion)
       }
    
   
    func getLast5Transactions(request: RequestLast5Transactions, completion: @escaping (Result<JResponseService, Error>) -> Void) {
        let endpoint = "api/wallet/transactions/last5"
        performRequest(endpoint: endpoint, method: .POST, body: request, requiresAuth: true, completion: completion)
    }

    func downloadEStatement(request: RequestEStatement, completion: @escaping (Result<ResponseService, Error>) -> Void) {
        let endpoint = "api/wallet/estatement"
        performRequest(endpoint: endpoint, method: .POST, body: request, requiresAuth: true, completion: completion)
    }
    func getPendingTransactions(request: RequestListPendingTransactions, completion: @escaping (Result<JResponseService, Error>) -> Void) {
        let endpoint = "api/wallet/transactions/pending"
        performRequest(endpoint: endpoint, method: .POST, body: request, requiresAuth: true, completion: completion)
    }

    func validateTransaction(request: RequestApproval, completion: @escaping (Result<ResponseService, Error>) -> Void) {
        let endpoint = "api/wallet/validate-transaction"
        performRequest(endpoint: endpoint, method: .POST, body: request, requiresAuth: true, completion: completion)
    }
       
    // Check PIN
       func checkPin(request: RequestCheckPin, completion: @escaping (Result<ResponseServiceJson, Error>) -> Void) {
           let endpoint = "api/wallet/check-pin"
           performRequest(endpoint: endpoint, method: .POST, body: request, requiresAuth: true, completion: completion)
       }
       
       // Change PIN
       func changePin(request: RequestChangePin, completion: @escaping (Result<ResponseService, Error>) -> Void) {
           let endpoint = "api/pin/change"
           performRequest(endpoint: endpoint, method: .POST, body: request, requiresAuth: true, completion: completion)
       }
    func getSponsoredWallets(request: RequestListSponsoredWallets, completion: @escaping (Result<JResponseService, Error>) -> Void) {
        let endpoint = "api/sponsor/sponsored-wallets"
        performRequest(endpoint: endpoint, method: .POST, body: request, requiresAuth: true, completion: completion)
    }
    
    func moneyVoucher(request: RequestMoneyVoucher, completion: @escaping (Result<ResponseService, Error>) -> Void) {
        let endpoint = "api/wallet/money-voucher"
        performRequest(endpoint: endpoint, method: .POST, body: request, requiresAuth: true, completion: completion)
    }
    func accountToWallet(request: RequestAccountToWallet, completion: @escaping (Result<ResponseServiceJson, Error>) -> Void) {
        let endpoint = "api/wallet/account-to-wallet"
        performRequest(endpoint: endpoint, method: .POST, body: request, requiresAuth: true, completion: completion)
    }

    func getAccountNameEnquiry(request: RequestWalletToBankAccountNE, completion: @escaping (Result<ResponseServiceJson, Error>) -> Void) {
        let endpoint = "api/wallet/account-name-enquiry"
        performRequest(endpoint: endpoint, method: .POST, body: request, requiresAuth: true, completion: completion)
    }
  
    func transferWalletToAccountNE(request: RequestWalletToBankAccountNE, completion: @escaping (Result<ResponseServiceJson, Error>) -> Void) {
        let endpoint = "api/wallet/account-name-enquiry"
        performRequest(endpoint: endpoint, method: .POST, body: request, requiresAuth: true, completion: completion)
    }

    func transferWalletToAccount(request: RequestWalletToAccount, completion: @escaping (Result<ResponseServiceJson, Error>) -> Void) {
        let endpoint = "api/wallet/transfer-to-account"
        performRequest(endpoint: endpoint, method: .POST, body: request, requiresAuth: true, completion: completion)
    }
    
    
    func getWalletInfo(request: RequestNameEnquiry, completion: @escaping (Result<ResponseServiceJson, Error>) -> Void) {
        let endpoint = "api/wallet/enquiry"
        performRequest(endpoint: endpoint, method: .POST, body: request, requiresAuth: true, completion: completion)
    }
    
 
    func transferWalletToWallet(request: RequestWalletToWallet, completion: @escaping (Result<ResponseServiceJson, Error>) -> Void) {
        let endpoint = "api/wallet/transfer"
        performRequest(endpoint: endpoint, method: .POST, body: request, requiresAuth: true, completion: completion)
    }
    func registerCustomer(
            request: CustomerRegistrationRequest,
            completion: @escaping (Result<ResponseServiceJson, Error>) -> Void
        ) {
            let endpoint = "api/customer/register"
            performRequest(endpoint: endpoint,
                           method: .POST,
                           body: request,
                           requiresAuth: false,
                           customTimeout: uploadTimeout,
                           completion: completion)
        }

        // Verify OTP (Step 4)
        func verifyOtp(
            request: OtpRequest,
            completion: @escaping (Result<ResponseServiceJson, Error>) -> Void
        ) {
            let endpoint = "api/otp/verify"
            performRequest(endpoint: endpoint,
                           method: .POST,
                           body: request,
                           requiresAuth: false,
                           completion: completion)
        }

    func getWalletBalance( request: RequestBalanceEnquiry, completion: @escaping (Result<ResponseServiceJson, Error>) -> Void ) { let endpoint = "api/wallet/balance"
        performRequest(endpoint: endpoint, method: .POST, body: request, requiresAuth: true, completion: completion) }
    
    func getLast30DaysTransactions( request: RequestEStatement, completion: @escaping (Result<JResponseService, Error>) -> Void ) { let endpoint = "api/wallet/lastThirty"
        performRequest(endpoint: endpoint, method: .POST, body: request, requiresAuth: true, completion: completion) } // MA
    // MARK: - Initialize
    func initialize(with userDataManager: UserDataManager) {
        self.userDataManager = userDataManager
    }
    func getBalance(completion: @escaping (Result<BalanceResponse, Error>) -> Void) {
           let endpoint = "api/wallet/balance"
           performRequest(endpoint: endpoint, method: .GET, body: nil as String?, requiresAuth: true, completion: completion)
       }
       
    func getSponsoringWallets(request: RequestListSponsoringWallets, completion: @escaping (Result<JResponseService, Error>) -> Void) {
        let endpoint = "api/sponsor/list-sponsoring-wallets"
        performRequest(endpoint: endpoint, method: .POST, body: request, requiresAuth: true, completion: completion)
    }
    
    func getDailyLimit(request: RequestGetDailyLimitSponsorWallet, completion: @escaping (Result<ResponseService, Error>) -> Void) {
        let endpoint = "api/sponsor/daily-limits"
        performRequest(endpoint: endpoint, method: .POST, body: request, requiresAuth: true, completion: completion)
    }
    
   
    func getLinkedAccounts(request: RequestListLinkedAcc, completion: @escaping (Result<JResponseService, Error>) -> Void) {
        let endpoint = "api/wallet/linked-accounts"
        performRequest(endpoint: endpoint, method: .POST, body: request, requiresAuth: true, completion: completion)
    }

    func getAccountBalance(accountNumber: String, clientId: String, completion: @escaping (Result<BalanceResponsea, Error>) -> Void) {
        let endpoint = "api/account/balance/\(accountNumber)?clientId=\(clientId)"
        performRequest(endpoint: endpoint, method: .GET, body: nil as String?, requiresAuth: true, completion: completion)
    }
     
    // MARK: - Auth Endpoints
    func login(request: AuthRequest, completion: @escaping (Result<AuthResponse, Error>) -> Void) {
        let endpoint = "api/auth/login"
        performRequest(endpoint: endpoint, method: .POST, body: request, requiresAuth: false, completion: completion)
    }
    
    func verifyOtp(request: OtpVerificationRequest, completion: @escaping (Result<AuthResponse, Error>) -> Void) {
        let endpoint = "api/auth/verify-otp"
        performRequest(endpoint: endpoint, method: .POST, body: request, requiresAuth: false, completion: completion)
    }
    
    func initPassword(request: AuthRequest, completion: @escaping (Result<AuthResponse, Error>) -> Void) {
        let endpoint = "api/auth/init-password"
        performRequest(endpoint: endpoint, method: .POST, body: request, requiresAuth: false, completion: completion)
    }
    
    func initiateForgotPin(request: ForgotPinInitiateRequest, completion: @escaping (Result<ForgotPinResponse, Error>) -> Void) {
        let endpoint = "api/auth/forgot-pin/initiate"
        performRequest(endpoint: endpoint, method: .POST, body: request, requiresAuth: false, completion: completion)
    }
    
    func verifyOtpReset(request: ForgotPinVerifyRequest, completion: @escaping (Result<ForgotPinResponse, Error>) -> Void) {
        let endpoint = "api/auth/forgot-pin/verify-otp"
        performRequest(endpoint: endpoint, method: .POST, body: request, requiresAuth: false, completion: completion)
    }
    
    func verifySecurityQuestion(request: SecurityQuestionRequest, completion: @escaping (Result<ForgotPinResponse, Error>) -> Void) {
        let endpoint = "api/auth/forgot-pin/verify-question"
        performRequest(endpoint: endpoint, method: .POST, body: request, requiresAuth: false, completion: completion)
    }
    
    func resetPin(request: PinResetRequest, completion: @escaping (Result<ForgotPinResponse, Error>) -> Void) {
        let endpoint = "api/auth/forgot-pin/reset"
        performRequest(endpoint: endpoint, method: .POST, body: request, requiresAuth: false, completion: completion)
    }
    

    // MARK: - List Standing Instructions
       func listStandingInstructions(
           request: RequestStandingInstructionList,
           completion: @escaping (Result<JResponseService, Error>) -> Void
       ) {
           let endpoint = "api/standing-instruction/list"
           performRequest(endpoint: endpoint, method: .POST, body: request, requiresAuth: true, completion: completion)
       }
       
       // MARK: - Create Standing Instruction
       func createStandingInstruction(
           request: StandingInstructionDto,
           completion: @escaping (Result<ResponseServiceJson, Error>) -> Void
       ) {
           let endpoint = "api/standing-instruction/create"
           performRequest(endpoint: endpoint, method: .POST, body: request, requiresAuth: true, completion: completion)
       }
       
       // MARK: - Update Standing Instruction
       func updateStandingInstruction(
           request: StandingInstructionUpdateRequest,
           completion: @escaping (Result<ResponseService, Error>) -> Void
       ) {
           let endpoint = "api/standing-instruction/update"
           performRequest(endpoint: endpoint, method: .POST, body: request, requiresAuth: true, completion: completion)
       }
       
       // MARK: - Delete Standing Instruction
       func deleteStandingInstruction(
           request: RequestStandingInstructionDelete,
           completion: @escaping (Result<ResponseService, Error>) -> Void
       ) {
           let endpoint = "api/standing-instruction/delete"
           performRequest(endpoint: endpoint, method: .POST, body: request, requiresAuth: true, completion: completion)
       }
    
       func sendComment(request: CommentRequest, completion: @escaping (Result<Void, Error>) -> Void) {
           let endpoint = "api/comments"
           
           guard let url = URL(string: baseURL + endpoint) else {
               completion(.failure(APIError(success: false, message: "Invalid URL", respCode: nil, details: nil)))
               return
           }
           
           var urlRequest = URLRequest(url: url)
           urlRequest.httpMethod = "POST"
           urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
           urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
           
           addAuthHeaders(to: &urlRequest)
           
           do {
               let encoder = JSONEncoder()
               encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
               let jsonData = try encoder.encode(request)
               urlRequest.httpBody = jsonData
               
               if let jsonString = String(data: jsonData, encoding: .utf8) {
                   print("=== COMMENT REQUEST JSON ===")
                   print(jsonString)
               }
           } catch {
               print("Error encoding comment request: \(error)")
               completion(.failure(error))
               return
           }
           
           session.dataTask(with: urlRequest) { data, response, error in
               DispatchQueue.main.async {
                   if let error = error {
                       print("❌ Comment network error: \(error)")
                       completion(.failure(error))
                       return
                   }
                   
                   guard let httpResponse = response as? HTTPURLResponse else {
                       completion(.failure(APIError(success: false, message: "Invalid response", respCode: nil, details: nil)))
                       return
                   }
                   
                   
                   switch httpResponse.statusCode {
                   case 200...299:
                       print("Comment sent successfully")
                       completion(.success(()))
                   case 400:
                       completion(.failure(APIError(success: false, message: "Données invalides", respCode: "400", details: nil)))
                   case 401:
                       completion(.failure(APIError(success: false, message: "Non autorisé", respCode: "401", details: nil)))
                   case 500...599:
                       completion(.failure(APIError(success: false, message: "Erreur du serveur", respCode: "\(httpResponse.statusCode)", details: nil)))
                   default:
                       completion(.failure(APIError(success: false, message: "Erreur inconnue", respCode: "\(httpResponse.statusCode)", details: nil)))
                   }
               }
           }.resume()
       }
       
       func sendComplaint(request: ComplaintRequest, completion: @escaping (Result<Void, Error>) -> Void) {
           let endpoint = "api/complaints"
           
           guard let url = URL(string: baseURL + endpoint) else {
               completion(.failure(APIError(success: false, message: "Invalid URL", respCode: nil, details: nil)))
               return
           }
           
           var urlRequest = URLRequest(url: url)
           urlRequest.httpMethod = "POST"
           urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
           urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
           
           addAuthHeaders(to: &urlRequest)
           
           do {
               let encoder = JSONEncoder()
               encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
               let jsonData = try encoder.encode(request)
               urlRequest.httpBody = jsonData
               
               if let jsonString = String(data: jsonData, encoding: .utf8) {
                   print(" === COMPLAINT REQUEST JSON ===")
                   print(jsonString)
               }
           } catch {
               print("Error encoding complaint request: \(error)")
               completion(.failure(error))
               return
           }
           
           session.dataTask(with: urlRequest) { data, response, error in
               DispatchQueue.main.async {
                   if let error = error {
                       print(" Complaint network error: \(error)")
                       completion(.failure(error))
                       return
                   }
                   
                   guard let httpResponse = response as? HTTPURLResponse else {
                       completion(.failure(APIError(success: false, message: "Invalid response", respCode: nil, details: nil)))
                       return
                   }
                   
                   
                   switch httpResponse.statusCode {
                   case 200...299:
                       completion(.success(()))
                   case 400:
                       completion(.failure(APIError(success: false, message: "Données invalides", respCode: "400", details: nil)))
                   case 401:
                       completion(.failure(APIError(success: false, message: "Non autorisé", respCode: "401", details: nil)))
                   case 429:
                       completion(.failure(APIError(success: false, message: "Trop de plaintes récentes", respCode: "429", details: nil)))
                   case 500...599:
                       completion(.failure(APIError(success: false, message: "Erreur du serveur", respCode: "\(httpResponse.statusCode)", details: nil)))
                   default:
                       completion(.failure(APIError(success: false, message: "Erreur inconnue", respCode: "\(httpResponse.statusCode)", details: nil)))
                   }
               }
           }.resume()
       }
    
    func validateJWT(request: ValidateJwtRequest, completion: @escaping (Result<[String: Any], Error>) -> Void) {
            let endpoint = "api/wallet/validate-jwt"
            performRequest(endpoint: endpoint, method: .POST, body: request, requiresAuth: true) { (result: Result<ResponseWithDynamicResult, Error>) in
                switch result {
                case .success(let response):
                    completion(.success(response.toDictionary()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        
        func markTokenUsed(request: MarkTokenUsedRequest, completion: @escaping (Result<[String: Any], Error>) -> Void) {
            let endpoint = "api/wallet/mark-token-used"
            performRequest(endpoint: endpoint, method: .POST, body: request, requiresAuth: true) { (result: Result<ResponseWithDynamicResult, Error>) in
                switch result {
                case .success(let response):
                    completion(.success(response.toDictionary()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    
    
        func deactivateWallet(
            request: RequestDeactivateWallet,
            completion: @escaping (Result<ResponseService, Error>) -> Void
        ) {
            let endpoint = "api/wallet/deactivate"
            performRequest(
                endpoint: endpoint,
                method: .POST,
                body: request,
                requiresAuth: true,
                completion: completion
            )
        }
 
        func getAllBranches(
            bankCode: String,
            completion: @escaping (Result<[Branch], Error>) -> Void
        ) {
            let endpoint = "branches/\(bankCode)"
            
            guard let url = URL(string: baseURL + endpoint) else {
                completion(.failure(APIError(success: false, message: "Invalid URL", respCode: nil, details: nil)))
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = HTTPMethod.GET.rawValue
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
                        
            if let userDataManager = userDataManager {
                let token = userDataManager.getToken()
                if !token.isEmpty {
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    request.setValue(token, forHTTPHeaderField: "X-Auth-Token")
                }
            }
            
            session.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print(" Network error: \(error)")
                        completion(.failure(error))
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        print(" Invalid response type")
                        completion(.failure(APIError(success: false, message: "Invalid response", respCode: nil, details: nil)))
                        return
                    }
                    
                    
                    guard let data = data else {
                        print(" No data received")
                        completion(.failure(APIError(success: false, message: "No data received", respCode: nil, details: nil)))
                        return
                    }
                    
                    if let responseString = String(data: data, encoding: .utf8) {
                        let preview = String(responseString.prefix(500))
                        print("Response preview: \(preview)")
                    }
                    
                    switch httpResponse.statusCode {
                    case 200...299:
                        do {
                            // Parse as array of dictionaries first, then convert to Branch objects
                            if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                                var branches: [Branch] = []
                                
                                for dict in jsonArray {
                                    var branch = Branch()
                                    branch.id = dict["id"] as? String
                                    branch.name = dict["name"] as? String
                                    branch.address = dict["address"] as? String
                                    branch.location = dict["location"] as? String
                                    branch.phoneNumber = dict["phoneNumber"] as? String
                                    branch.bankCode = dict["bankCode"] as? String
                                    branches.append(branch)
                                }
                                
                                completion(.success(branches))
                            } else {
                                completion(.failure(APIError(success: false, message: "Invalid response format", respCode: nil, details: nil)))
                            }
                        } catch {
                            completion(.failure(error))
                        }
                        
                    case 401:
                        self.handleTokenExpiration()
                        let error = APIError(success: false, message: "Session expired", respCode: "401", details: "Please login again")
                        completion(.failure(error))
                        
                    default:
                        let error = APIError(success: false, message: "Server error", respCode: "\(httpResponse.statusCode)", details: nil)
                        completion(.failure(error))
                    }
                }
            }.resume()
        }
    // MARK: - Generic Request Method
    private func performRequest<T: Codable, U: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: T?,
        requiresAuth: Bool,
        customTimeout: TimeInterval? = nil,
        completion: @escaping (Result<U, Error>) -> Void
    ) {
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(APIError(success: false, message: "Invalid URL", respCode: nil, details: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Set custom timeout if provided
        if let timeout = customTimeout {
            request.timeoutInterval = timeout
            print("⏱️ Using custom timeout: \(timeout)s for \(endpoint)")
        }
        
        if requiresAuth {
            addAuthHeaders(to: &request)
        }
        
        if let body = body {
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let jsonData = try encoder.encode(body)
                request.httpBody = jsonData
                
                // Log payload size for debugging
                let sizeInKB = Double(jsonData.count) / 1024.0
                
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                }
            } catch {
                completion(.failure(error))
                return
            }
        } else {
            print("Request has body: NO")
        }

        // Perform the request
        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.handleResponse(data: data, response: response, error: error, completion: completion)
            }
        }.resume()
    }


    private func addAuthHeaders(to request: inout URLRequest) {
        guard let userDataManager = userDataManager else {
            return
        }

        let token = userDataManager.getToken()

        if !token.isEmpty {
            // Required headers
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue(token, forHTTPHeaderField: "X-Auth-Token")

            // User/device headers
            if !userDataManager.getUserCode().isEmpty {
                request.setValue(userDataManager.getUserCode(), forHTTPHeaderField: "X-User-Code")
            }

            var deviceId = userDataManager.getDeviceIdentifier()
            if deviceId.isEmpty {
                deviceId = APIClient.getDeviceId()
                UserDefaults.standard.set(deviceId, forKey: "device_identifier")
            }
            request.setValue(deviceId, forHTTPHeaderField: "X-Device-ID")

            if !userDataManager.getPhoneNumber().isEmpty {
                request.setValue(userDataManager.getPhoneNumber(), forHTTPHeaderField: "X-Phone-Number")
            }

            if !userDataManager.getWalletNumber().isEmpty {
                request.setValue(userDataManager.getWalletNumber(), forHTTPHeaderField: "X-Wallet-Number")
            }

            if !userDataManager.getBankCode().isEmpty {
                request.setValue(userDataManager.getBankCode(), forHTTPHeaderField: "X-Bank-Code")
            }

        } else {
            print("NO TOKEN AVAILABLE")
        }
    }


    private func handleResponse<T: Codable>(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(APIError(success: false, message: "Invalid response", respCode: nil, details: nil)))
            return
        }
        
        
        guard let data = data else {
            completion(.failure(APIError(success: false, message: "No data received", respCode: nil, details: nil)))
            return
        }
        
        if let responseString = String(data: data, encoding: .utf8) {
            let preview = String(responseString.prefix(500))
        }
//        if let responseString = String(data: data, encoding: .utf8) {
//
//            print("""
//            
//            ==================== 🔥 BACKEND RESPONSE 🔥 ====================
//            HTTP STATUS: \(httpResponse.statusCode)
//            
//            \(responseString)
//            
//            ==================================================================
//            
//            """)
//        }
        
        // 🔍 Print raw response body for debugging
            if let rawBody = String(data: data, encoding: .utf8) {
                print("""
                
                ==================== 🟢 RAW HTTP RESPONSE BODY (status \(httpResponse.statusCode)) ====================
                \(rawBody)
                ===========================================================================================
                
                """)
            } else {
                print("⚠️ Could not decode response data as UTF-8 string. Byte count: \(data.count)")
            }
        
        switch httpResponse.statusCode {
            
        case 200...299:
            // 🔍 Print raw response body for debugging
                if let rawBody = String(data: data, encoding: .utf8) {
                    print("""
                    
                    ==================== 🟢 RAW HTTP RESPONSE BODY (status \(httpResponse.statusCode)) ====================
                    \(rawBody)
                    ===========================================================================================
                    
                    """)
                } else {
                    print("⚠️ Could not decode response data as UTF-8 string. Byte count: \(data.count)")
                }
            
            do {
                let result = try JSONDecoder().decode(T.self, from: data)
                completion(.success(result))
            } catch {
                if let errorResponse = try? JSONDecoder().decode(APIError.self, from: data) {
                    completion(.failure(errorResponse))
                } else {
                    completion(.failure(error))
                }
            }
            
        case 401:
            if let authError = try? JSONDecoder().decode(APIError.self, from: data) {
                completion(.failure(authError))
            } else if let authResponse = try? JSONDecoder().decode(AuthResponse.self, from: data) {
                let error = APIError(success: false,
                                     message: authResponse.message ?? "Unauthorized",
                                     respCode: authResponse.respCode,
                                     details: "401 Unauthorized")
                completion(.failure(error))
            } else {
                handleTokenExpiration()
                let error = APIError(success: false, message: "Session expired", respCode: "401", details: "Please login again")
                completion(.failure(error))
            }
        case 403:
                // Handle version update requirement
                if let authResponse = try? JSONDecoder().decode(AuthResponse.self, from: data) {
                    let error = APIError(success: false,
                                         message: authResponse.message ?? "Access denied",
                                         respCode: authResponse.respCode,
                                         details: "VERSION_UPDATE_REQUIRED")
                    completion(.failure(error))
                } else {
                    let error = APIError(success: false, message: "Access denied", respCode: "403", details: "VERSION_UPDATE_REQUIRED")
                    completion(.failure(error))
                }
        case 400...499:
            // Client error
            if let errorResponse = try? JSONDecoder().decode(APIError.self, from: data) {
                completion(.failure(errorResponse))
            } else {
                let genericError = APIError(success: false, message: "Client error", respCode: "\(httpResponse.statusCode)", details: nil)
                completion(.failure(genericError))
            }
            
        case 500...599:
            let error = APIError(success: false, message: "Server error", respCode: "\(httpResponse.statusCode)", details: nil)
            completion(.failure(error))
            
        default:
            let error = APIError(success: false, message: "Unknown error", respCode: "\(httpResponse.statusCode)", details: nil)
            completion(.failure(error))
        }
    }

    
    private func handleTokenExpiration() {
        userDataManager?.clearAllUserData()
        
        // Post notification for token expiration
        NotificationCenter.default.post(name: .tokenExpired, object: nil)
    }
    
    // MARK: - Token Management
    func updateToken(_ newToken: String) {
        userDataManager?.updateToken(newToken)
    }
    
    func hasAuthToken() -> Bool {
        guard let userDataManager = userDataManager else { return false }
        let token = userDataManager.getToken()
        return !token.isEmpty && !userDataManager.isTokenExpired()
    }
    
    func getCurrentToken() -> String {
        return userDataManager?.getToken() ?? ""
    }
    
    func isAuthenticated() -> Bool {
        guard let userDataManager = userDataManager else { return false }
        return userDataManager.isLoggedIn() &&
               !userDataManager.isTokenExpired() &&
               !userDataManager.getToken().isEmpty
    }
    
 
    // Get DSD Pending Payments
    func getDSDPendingPayments(
        phoneNumber: String,
        completion: @escaping (Result<ResponseService, Error>) -> Void
    ) {
        let endpoint = "api/dsd/payments/pending/\(phoneNumber)"
        performRequest(
            endpoint: endpoint,
            method: .GET,
            body: nil as String?,
            requiresAuth: true,
            completion: completion
        )
    }

    // Validate DSD Payment
    func validateDSDPayment(
        operationId: String,
        phoneNumber: String,
        pin: String,
        completion: @escaping (Result<ResponseService, Error>) -> Void
    ) {
        let endpoint = "api/dsd/payments/validate"
        
        performDSDFormRequest(
            endpoint: endpoint,
            formData: [
                "operationId": operationId,
                "phoneNumber": phoneNumber,
                "pin": pin
            ],
            requiresAuth: true,
            completion: completion
        )
    }

    // Reject DSD Payment
    func rejectDSDPayment(
        operationId: String,
        phoneNumber: String,
        completion: @escaping (Result<ResponseService, Error>) -> Void
    ) {
        let endpoint = "api/dsd/payments/reject"
        
        performDSDFormRequest(
            endpoint: endpoint,
            formData: [
                "operationId": operationId,
                "phoneNumber": phoneNumber
            ],
            requiresAuth: true,
            completion: completion
        )
    }

    // Initiate DSD Payment
    func initiateDSDPayment(
        phoneNumber: String,
        chassisNumber: String,
        category: String,
        amount: String,
        completion: @escaping (Result<ResponseService, Error>) -> Void
    ) {
        let endpoint = "api/dsd/payments/initiate"
        
        performDSDFormRequest(
            endpoint: endpoint,
            formData: [
                "phoneNumber": phoneNumber,
                "chassisNumber": chassisNumber,
                "category": category,
                "amount": amount
            ],
            requiresAuth: true,
            completion: completion
        )
    }

    // Query DSD Payment Status
    func queryDSDPaymentStatus(
        operationId: String,
        completion: @escaping (Result<ResponseService, Error>) -> Void
    ) {
        let endpoint = "api/dsd/payments/status/\(operationId)"
        performRequest(
            endpoint: endpoint,
            method: .GET,
            body: nil as String?,
            requiresAuth: true,
            completion: completion
        )
    }

    // MARK: - DSD Helper Method (Form-Encoded Request)

    private func performDSDFormRequest(
        endpoint: String,
        formData: [String: String],
        requiresAuth: Bool,
        completion: @escaping (Result<ResponseService, Error>) -> Void
    ) {
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(APIError(success: false, message: "Invalid URL", respCode: nil, details: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if requiresAuth {
            addAuthHeaders(to: &request)
        }
        
        // Build form-encoded body
        let formString = formData.map { key, value in
            let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
            let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
            return "\(encodedKey)=\(encodedValue)"
        }.joined(separator: "&")
        
        request.httpBody = formString.data(using: .utf8)
        
        // Perform the request
        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.handleResponse(data: data, response: response, error: error, completion: completion)
            }
        }.resume()
    }
    
    // MARK: - Device Utilities
    static func getDeviceId() -> String {
        if let deviceId = UIDevice.current.identifierForVendor?.uuidString {
            return deviceId
        } else {
            // Generate a random UUID and store it
            let deviceId = UUID().uuidString
            UserDefaults.standard.set(deviceId, forKey: "device_id")
            return deviceId
        }
    }
}

// MARK: - HTTP Methods
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - Notification Names
extension Notification.Name {
    static let tokenExpired = Notification.Name("tokenExpired")
    static let logoutRequired = Notification.Name("logoutRequired")

}
