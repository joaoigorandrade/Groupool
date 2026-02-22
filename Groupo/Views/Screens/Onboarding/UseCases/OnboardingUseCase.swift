import Combine
import Foundation

protocol OnboardingUseCaseProtocol {
    func fetchInviteDetails() async throws -> (groupName: String, inviterName: String, buyInAmount: Decimal, rules: [String])
    func connectAndDeposit() async throws
}

final class OnboardingUseCase: OnboardingUseCaseProtocol {
    private let groupService: any GroupServiceProtocol
    
    init(groupService: any GroupServiceProtocol) {
        self.groupService = groupService
    }
    
    func fetchInviteDetails() async throws -> (groupName: String, inviterName: String, buyInAmount: Decimal, rules: [String]) {
        // Mocking the behavior based on original ViewModel
        try await Task.sleep(nanoseconds: 500_000_000)
        return (
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
