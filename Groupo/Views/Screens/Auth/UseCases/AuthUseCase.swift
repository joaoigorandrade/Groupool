import Foundation

protocol AuthUseCaseProtocol {
    func sendOTP(phoneNumber: String) async throws
}

final class AuthUseCase: AuthUseCaseProtocol {
    private let userService: any UserServiceProtocol
    
    init(userService: any UserServiceProtocol) {
        self.userService = userService
    }
    
    func sendOTP(phoneNumber: String) async throws {
        // In a real app, this would call the service
        // For now, we mock the behavior
        try await Task.sleep(nanoseconds: 1_000_000_000)
        print("UseCase: Sending OTP to \(phoneNumber)")
    }
}
