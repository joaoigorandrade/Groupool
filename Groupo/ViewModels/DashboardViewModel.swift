
import Combine
import Foundation
import Observation

@Observable
class DashboardViewModel {
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

    private var cancellables = Set<AnyCancellable>()
    private let groupService: any GroupServiceProtocol
    private let userService: any UserServiceProtocol
    private let challengeService: any ChallengeServiceProtocol
    private let transactionService: any TransactionServiceProtocol

    init(
        groupService: any GroupServiceProtocol,
        userService: any UserServiceProtocol,
        challengeService: any ChallengeServiceProtocol,
        transactionService: any TransactionServiceProtocol
    ) {
        self.groupService = groupService
        self.userService = userService
        self.challengeService = challengeService
        self.transactionService = transactionService
        setupSubscribers()
    }

    @MainActor
    func refresh() async {
        isLoading = true
        // In a real app, we might trigger a refresh on the services here.
        // For now, the services are reactive, so we just wait a bit to simulate network delay if needed, 
        // or just rely on the streams updating.
        try? await Task.sleep(nanoseconds: 500_000_000)
        isLoading = false
    }

    private func setupSubscribers() {
        // Group Data
        groupService.currentGroup
            .receive(on: DispatchQueue.main)
            .sink { [weak self] group in
                self?.totalPool = group.totalPool
                self?.members = group.members
            }
            .store(in: &cancellables)
            
        // User & Challenge Data for Personal Stake
        Publishers.CombineLatest(userService.currentUser, challengeService.challenges)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user, challenges in
                self?.currentUser = user
                self?.challenges = challenges
                self?.calculateStake(user: user, challenges: challenges)
            }
            .store(in: &cancellables)
            
        // Transaction Data
        transactionService.transactions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] transactions in
                self?.transactions = transactions
            }
            .store(in: &cancellables)
    }
    
    private func calculateStake(user: User, challenges: [Challenge]) {
        let total = user.currentEquity
        
        // Calculate frozen amount: Sum of buyIns for active challenges where user is a participant
        let activeChallenges = challenges.filter { challenge in
            let isActive = challenge.status == .active || challenge.status == .voting
            let isParticipant = challenge.participants.contains(user.id)
            return isActive && isParticipant
        }
        
        let frozen = activeChallenges.reduce(Decimal(0)) { sum, challenge in
            sum + challenge.buyIn
        }
        
        let available = total - frozen
        
        self.totalStake = total
        self.frozenStake = frozen
        self.availableStake = available
    }
}
