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
    
    var activeChallenge: Challenge? {
        challenges.first { $0.status == .active || $0.status == .voting }
    }
    
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
    
    @MainActor
    func refresh() async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 500_000_000)
        isLoading = false
    }
    
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
                self?.currentUser = user
                self?.challenges = challenges
                self?.calculateStake(user: user, challenges: challenges)
            }
            .store(in: &cancellables)
            
        transactionUseCase.transactions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] transactions in
                self?.transactions = transactions
            }
            .store(in: &cancellables)
    }
    
    private func calculateStake(user: User, challenges: [Challenge]) {
        let total = user.currentEquity
        let activeChallenges = challenges.filter { challenge in
            let isActive = challenge.status == .active || challenge.status == .voting
            let isParticipant = challenge.participants.contains(user.id)
            return isActive && isParticipant
        }
        let frozen = activeChallenges.reduce(Decimal(0)) { $0 + $1.buyIn }
        let available = total - frozen
        
        self.totalStake = total
        self.frozenStake = frozen
        self.availableStake = available
    }
}
