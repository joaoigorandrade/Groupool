import Combine
import Foundation

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

    var createdDate: Date {
        switch self {
        case .challenge(let challenge): return challenge.createdDate
        case .withdrawal(let request): return request.createdDate
        }
    }
}

class GovernanceViewModel: ObservableObject {
    @Published var activeItems: [GovernanceItem] = []
    @Published var currentTime: Date = Date()
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    private let challengeService: any ChallengeServiceProtocol
    private let voteService: any VoteServiceProtocol
    private let withdrawalService: any WithdrawalServiceProtocol
    private let userService: any UserServiceProtocol
    private let groupService: any GroupServiceProtocol

    private var currentUser: User?
    private var currentGroup: Group?
    private var latestVotes: [Vote] = []

    init(
        challengeService: any ChallengeServiceProtocol,
        voteService: any VoteServiceProtocol,
        withdrawalService: any WithdrawalServiceProtocol,
        userService: any UserServiceProtocol,
        groupService: any GroupServiceProtocol
    ) {
        self.challengeService = challengeService
        self.voteService = voteService
        self.withdrawalService = withdrawalService
        self.userService = userService
        self.groupService = groupService
        print("GovernanceViewModel initialized with services")
        addSubscribers()
        setupTimer()
    }

    @MainActor
    func refresh() async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isLoading = false
    }

    // MARK: - Subscribers

    private func addSubscribers() {
        challengeService.challenges
            .combineLatest(withdrawalService.withdrawalRequests)
            .receive(on: DispatchQueue.main)
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

        userService.currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.currentUser = user
            }
            .store(in: &cancellables)

        groupService.currentGroup
            .receive(on: DispatchQueue.main)
            .sink { [weak self] group in
                self?.currentGroup = group
            }
            .store(in: &cancellables)

        voteService.votes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] votes in
                self?.latestVotes = votes
            }
            .store(in: &cancellables)
    }

    private func setupTimer() {
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.currentTime = Date()
                Task { [weak self] in
                    await self?.withdrawalService.verifyExpiredWithdrawals()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Helpers

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

    func progress(for item: GovernanceItem) -> Double {
        let totalDuration = item.deadline.timeIntervalSince(item.createdDate)
        let elapsed = currentTime.timeIntervalSince(item.createdDate)

        guard totalDuration > 0 else { return 1.0 }

        let progress = elapsed / totalDuration
        return min(max(progress, 0.0), 1.0)
    }

    // MARK: - Actions

    @MainActor
    func castVote(challenge: Challenge, type: Vote.VoteType) async {
        isLoading = true
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            try await voteService.castVote(targetID: challenge.id, type: type)
            HapticManager.notificationSuccess()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    func castVote(withdrawal: WithdrawalRequest, type: Vote.VoteType, reason: String? = nil) async {
        isLoading = true
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            try await voteService.castVote(targetID: withdrawal.id, type: type)
            HapticManager.notificationSuccess()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    func joinChallenge(challenge: Challenge) async {
        isLoading = true
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            try await challengeService.joinChallenge(id: challenge.id)
            HapticManager.notificationSuccess()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    func submitProof(challenge: Challenge, image: String?) async {
        isLoading = true
        do {
            try await Task.sleep(nanoseconds: 1_200_000_000)
            try await challengeService.submitProof(
                challengeID: challenge.id,
                imageData: image?.data(using: .utf8)
            )
            HapticManager.notificationSuccess()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    func resolveChallenge(challenge: Challenge) async {
        isLoading = true
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            try await challengeService.resolveVoting(challengeID: challenge.id)
            HapticManager.notificationSuccess()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    func startVoting(challenge: Challenge) async {
        isLoading = true
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            try await challengeService.startVoting(challengeID: challenge.id)
            HapticManager.notificationSuccess()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func getUser(for id: UUID) -> User? {
        if currentUser?.id == id {
            return currentUser
        }
        return currentGroup?.members.first { $0.id == id }
    }

    func hasVoted(on item: GovernanceItem) -> Bool {
        guard let userId = currentUser?.id else { return false }
        return latestVotes.contains { $0.targetID == item.id && $0.voterID == userId }
    }

    func isEligibleToVote(on item: GovernanceItem) -> Bool {
        guard let userId = currentUser?.id else { return false }
        switch item {
        case .challenge(let challenge):
            return challenge.participants.contains(userId)
        case .withdrawal:
            return true
        }
    }
}
