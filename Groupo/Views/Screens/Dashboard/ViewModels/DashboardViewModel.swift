import Combine
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
    private let groupUseCase: DashboardGroupUseCaseProtocol
    private let challengeUseCase: DashboardChallengeUseCaseProtocol
    private let transactionUseCase: DashboardTransactionUseCaseProtocol
    private let userUseCase: DashboardUserUseCaseProtocol

    private var cancellables = Set<AnyCancellable>()

    init(
        groupUseCase: DashboardGroupUseCaseProtocol,
        challengeUseCase: DashboardChallengeUseCaseProtocol,
        transactionUseCase: DashboardTransactionUseCaseProtocol,
        userUseCase: DashboardUserUseCaseProtocol
    ) {
        self.groupUseCase = groupUseCase
        self.challengeUseCase = challengeUseCase
        self.transactionUseCase = transactionUseCase
        self.userUseCase = userUseCase
        setupSubscribers()
    }

    // MARK: - Refresh

    @MainActor
    func refresh() async {
        isLoading = true
        errorMessage = nil
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.groupUseCase.refresh() }
            group.addTask { await self.challengeUseCase.refresh() }
            group.addTask { await self.userUseCase.refresh() }
            group.addTask { await self.transactionUseCase.refresh() }
        }
        isLoading = false
    }

    // MARK: - Subscribers

    private func setupSubscribers() {
        groupUseCase.currentGroup
            .receive(on: DispatchQueue.main)
            .sink { [weak self] group in
                self?.totalPool = group.totalPool
                self?.members = group.members
            }
            .store(in: &cancellables)

        Publishers.CombineLatest(userUseCase.currentUser, challengeUseCase.challenges)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user, challenges in
                guard let self else { return }
                self.currentUser = user
                self.challenges = challenges
                self.activeChallenge = challenges.first { $0.status == .active || $0.status == .voting }
                self.calculateStake(user: user, challenges: challenges)
            }
            .store(in: &cancellables)

        transactionUseCase.transactions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] transactions in
                self?.transactions = transactions
            }
            .store(in: &cancellables)
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
