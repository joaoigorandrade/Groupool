// AppServiceContainer.swift

import Foundation
import SwiftUI

final class AppServiceContainer {

    // MARK: - Services (protocol types, not concrete)

    let userService: any UserServiceProtocol
    let groupService: any GroupServiceProtocol
    let challengeService: any ChallengeServiceProtocol
    let transactionService: any TransactionServiceProtocol
    let voteService: any VoteServiceProtocol
    let withdrawalService: any WithdrawalServiceProtocol
    let authService: any AuthServiceProtocol
    let pixService: any PIXServiceProtocol
    let onboardingService: any OnboardingServiceProtocol

    // MARK: - Private

    private let store: MockStore?

    // MARK: - Designated Init

    init(
        userService: any UserServiceProtocol,
        groupService: any GroupServiceProtocol,
        challengeService: any ChallengeServiceProtocol,
        transactionService: any TransactionServiceProtocol,
        voteService: any VoteServiceProtocol,
        withdrawalService: any WithdrawalServiceProtocol,
        authService: any AuthServiceProtocol,
        pixService: any PIXServiceProtocol,
        onboardingService: any OnboardingServiceProtocol,
        store: MockStore? = nil
    ) {
        self.userService = userService
        self.groupService = groupService
        self.challengeService = challengeService
        self.transactionService = transactionService
        self.voteService = voteService
        self.withdrawalService = withdrawalService
        self.authService = authService
        self.pixService = pixService
        self.onboardingService = onboardingService
        self.store = store
    }

    // MARK: - Helper Methods

    func resetMockData() {
        store?.reset()
    }
}

// MARK: - Factories

extension AppServiceContainer {

    static func mock(seed: MockSeed = .default) -> AppServiceContainer {
        let store = MockStore(seed: seed)

        return AppServiceContainer(
            userService: MockUserService(store: store),
            groupService: MockGroupService(store: store),
            challengeService: MockChallengeService(store: store),
            transactionService: MockTransactionService(store: store),
            voteService: MockVoteService(store: store),
            withdrawalService: MockWithdrawalService(store: store),
            authService: MockAuthService(),
            pixService: MockPIXService(),
            onboardingService: MockOnboardingService(),
            store: store
        )
    }

    static func preview(seed: MockSeed = .default) -> AppServiceContainer {
        let store = MockStore(seed: seed, persistenceEnabled: false)

        return AppServiceContainer(
            userService: MockUserService(store: store),
            groupService: MockGroupService(store: store),
            challengeService: MockChallengeService(store: store),
            transactionService: MockTransactionService(store: store),
            voteService: MockVoteService(store: store),
            withdrawalService: MockWithdrawalService(store: store),
            authService: MockAuthService(),
            pixService: MockPIXService(),
            onboardingService: MockOnboardingService(),
            store: store
        )
    }

    static func live() -> AppServiceContainer {
        fatalError(
            "Live services not implemented yet. See Services/Live/ to implement."
        )
    }
}

// MARK: - Environment

private struct AppServiceContainerKey: EnvironmentKey {
    static let defaultValue: AppServiceContainer = .mock()
}

extension EnvironmentValues {
    var services: AppServiceContainer {
        get { self[AppServiceContainerKey.self] }
        set { self[AppServiceContainerKey.self] = newValue }
    }
}
