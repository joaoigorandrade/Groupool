import Foundation
import Combine

enum GovernanceItem: Identifiable, Hashable {
    case challenge(Challenge)
    case withdrawal(WithdrawalRequest)
    
    var id: UUID {
        switch self {
        case .challenge(let challenge): return challenge.id
        case .withdrawal(let request): return request.id
        }
    }
    
    var deadline: Date {
        switch self {
        case .challenge(let challenge): return challenge.deadline
        case .withdrawal(let request): return request.deadline
        }
    }
}

class GovernanceViewModel: ObservableObject {
    @Published var activeItems: [GovernanceItem] = []
    @Published var currentTime: Date = Date()
    
    private var cancellables = Set<AnyCancellable>()
    private var mockDataService: MockDataService
    
    init(mockDataService: MockDataService = MockDataService()) {
        self.mockDataService = mockDataService
        addSubscribers()
        setupTimer()
    }
    
    func setService(_ service: MockDataService) {
        self.mockDataService = service
        self.cancellables.removeAll()
        addSubscribers()
        setupTimer()
    }
    
    private func addSubscribers() {
        Publishers.CombineLatest(mockDataService.$challenges, mockDataService.$withdrawalRequests)
            .map { (challenges, withdrawals) -> [GovernanceItem] in
                var items: [GovernanceItem] = []
                let activeChallenges = challenges.filter { $0.status == .active || $0.status == .voting }
                items.append(contentsOf: activeChallenges.map { GovernanceItem.challenge($0) })
                
                let pendingWithdrawals = withdrawals.filter { $0.status == .pending }
                items.append(contentsOf: pendingWithdrawals.map { GovernanceItem.withdrawal($0) })
                
                return items.sorted { $0.deadline < $1.deadline }
            }
            .assign(to: \.activeItems, on: self)
            .store(in: &cancellables)
    }
    
    private func setupTimer() {
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.currentTime = Date()
                self?.mockDataService.verifyExpiredWithdrawals()
            }
            .store(in: &cancellables)
    }
    
    func timeRemaining(for deadline: Date) -> String {
        let remaining = deadline.timeIntervalSince(currentTime)
        if remaining <= 0 {
            return "Expired"
        }
        
        let days = Int(remaining) / (3600 * 24)
        
        if days > 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            return formatter.string(from: deadline)
        } else if days >= 1 {
            let hours = Int(remaining) / 3600 % 24
            let minutes = Int(remaining) / 60 % 60
            let seconds = Int(remaining) % 60
            return String(format: "%d days and %02d:%02d:%02d", days, hours, minutes, seconds)
        } else {
            let hours = Int(remaining) / 3600
            let minutes = Int(remaining) / 60 % 60
            let seconds = Int(remaining) % 60
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
    }
    
    func castVote(challenge: Challenge, type: Vote.VoteType) {
        mockDataService.castVote(targetID: challenge.id, type: type)
    }
    
    func castVote(withdrawal: WithdrawalRequest, type: Vote.VoteType, reason: String? = nil) {
        mockDataService.castVote(targetID: withdrawal.id, type: type)
    }
    
    func joinChallenge(challenge: Challenge) {
        mockDataService.joinChallenge(challengeID: challenge.id)
    }
    
    func submitProof(challenge: Challenge, image: String?) {
        mockDataService.submitProof(challengeID: challenge.id, image: image)
    }
    
    func resolveChallenge(challenge: Challenge) {
        mockDataService.resolveChallengeVoting(challengeID: challenge.id)
    }
    
    func getUser(for id: UUID) -> User? {
        if mockDataService.currentUser.id == id {
            return mockDataService.currentUser
        }
        return mockDataService.currentGroup.members.first { $0.id == id }
    }
    
    func hasVoted(on item: GovernanceItem) -> Bool {
        return mockDataService.votes.contains { $0.targetID == item.id && $0.voterID == mockDataService.currentUser.id }
    }
    
    func isEligibleToVote(on item: GovernanceItem) -> Bool {
        switch item {
        case .challenge(let challenge):
            return challenge.participants.contains(mockDataService.currentUser.id)
        case .withdrawal:
            return true
        }
    }
}
