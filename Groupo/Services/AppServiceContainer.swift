// AppServiceContainer.swift

import Combine
import Foundation

final class AppServiceContainer: ObservableObject {

    let objectWillChange = ObservableObjectPublisher()

    // MARK: - Services (protocol types, not concrete)

    let userService: any UserServiceProtocol
    let groupService: any GroupServiceProtocol
    let challengeService: any ChallengeServiceProtocol
    let transactionService: any TransactionServiceProtocol
    let voteService: any VoteServiceProtocol
    let withdrawalService: any WithdrawalServiceProtocol

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
        store: MockStore? = nil
    ) {
        self.userService = userService
        self.groupService = groupService
        self.challengeService = challengeService
        self.transactionService = transactionService
        self.voteService = voteService
        self.withdrawalService = withdrawalService
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
            store: store
        )
    }

    static func live() -> AppServiceContainer {
        fatalError(
            "Live services not implemented yet. See Services/Live/ to implement."
        )
    }
}
