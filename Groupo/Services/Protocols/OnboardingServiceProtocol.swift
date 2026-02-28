// OnboardingServiceProtocol.swift

import Foundation

protocol OnboardingServiceProtocol: AnyObject {

    // MARK: - Actions

    func fetchInviteDetails() async throws -> InviteDetails
    func connectAndDeposit() async throws
}
