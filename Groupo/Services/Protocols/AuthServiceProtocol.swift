// AuthServiceProtocol.swift

import Foundation

protocol AuthServiceProtocol: AnyObject {

    // MARK: - Actions

    func sendOTP(phoneNumber: String) async throws
    func verifyOTP(phoneNumber: String, code: String) async throws -> String
}
