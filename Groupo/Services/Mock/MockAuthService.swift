// MockAuthService.swift

import Foundation

final class MockAuthService: AuthServiceProtocol {

    // MARK: - Actions

    func sendOTP(phoneNumber: String) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }

    func verifyOTP(phoneNumber: String, code: String) async throws -> String {
        try await Task.sleep(nanoseconds: 1_000_000_000)

        guard code == "123456" else {
            throw ServiceError.unauthorized
        }

        return "mock_auth_token_\(UUID().uuidString)"
    }
}
