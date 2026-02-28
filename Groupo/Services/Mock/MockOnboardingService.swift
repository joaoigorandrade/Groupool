// MockOnboardingService.swift

import Foundation

final class MockOnboardingService: OnboardingServiceProtocol {

    // MARK: - Actions

    func fetchInviteDetails() async throws -> InviteDetails {
        try await Task.sleep(nanoseconds: 500_000_000)

        return InviteDetails(
            groupName: "The Fellowship of the Ring",
            inviterName: "Gandalf",
            buyInAmount: 50.0,
            rules: [
                "Keep it secret, keep it safe.",
                "All members must vote on all proposals.",
                "Withdrawals require majority approval."
            ]
        )
    }

    func connectAndDeposit() async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }
}
