import Foundation

protocol VerifyOTPUseCaseProtocol {
    func verifyOTP(phoneNumber: String, code: String) async throws -> String
}

final class VerifyOTPUseCase: VerifyOTPUseCaseProtocol {
    private let userService: any UserServiceProtocol
    
    init(userService: any UserServiceProtocol) {
        self.userService = userService
    }
    
    func verifyOTP(phoneNumber: String, code: String) async throws -> String {
        // Mock verification logic
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        if code == "123456" {
            return "mock_auth_token_\(UUID().uuidString)"
        } else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid code. Please try again."])
        }
    }
}
