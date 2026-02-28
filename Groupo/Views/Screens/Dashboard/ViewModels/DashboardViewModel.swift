import Foundation
import Observation

@Observable
final class DashboardViewModel {
    // MARK: - State
    var totalPool: Decimal = 0
    var members: [User] = []
    var totalStake: Decimal = 0
    var frozenStake: Decimal = 0
    var availableStake: Decimal = 0
    var currentUser: User?
    var challenges: [Challenge] = []
    var transactions: [Transaction] = []

    /// Cached to avoid re-filtering on every render cycle.
    private(set) var activeChallenge: Challenge?

    var isLoading: Bool = false
    var errorMessage: String?

    // MARK: - Dependencies
    private let groupService: any GroupServiceProtocol
    private let challengeService: any ChallengeServiceProtocol
    private let transactionService: any TransactionServiceProtocol
    private let userService: any UserServiceProtocol

    init(
        userService: any UserServiceProtocol,
        groupService: any GroupServiceProtocol,
        challengeService: any ChallengeServiceProtocol,
        transactionService: any TransactionServiceProtocol
    ) {
        self.userService = userService
        self.groupService = groupService
        self.challengeService = challengeService
        self.transactionService = transactionService
        syncState()
    }

    // MARK: - Refresh

    @MainActor
    func refresh() async {
        isLoading = true
        errorMessage = nil
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.groupService.refresh() }
            group.addTask { await self.challengeService.refresh() }
            group.addTask { await self.userService.refresh() }
            group.addTask { await self.transactionService.refresh() }
        }
        syncState()
        isLoading = false
    }

    // MARK: - State Sync

    private func syncState() {
        let group = groupService.currentGroup
        totalPool = group.totalPool
        members = group.members

        let user = userService.currentUser
        currentUser = user

        challenges = challengeService.challenges
        activeChallenge = challenges.first { $0.status == .active || $0.status == .voting }
        calculateStake(user: user, challenges: challenges)

        transactions = transactionService.transactions
    }

    // MARK: - Stake Calculation

    private func calculateStake(user: User, challenges: [Challenge]) {
        let total = user.currentEquity
        let frozen = ChallengeStakeCalculator.frozenAmount(for: user.id, in: challenges)

        self.totalStake = total
        self.frozenStake = frozen
        self.availableStake = total - frozen
    }
}
