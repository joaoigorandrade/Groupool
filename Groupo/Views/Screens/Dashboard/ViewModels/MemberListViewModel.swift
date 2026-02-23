
import Combine
import Foundation
import Observation

@Observable
class MemberListViewModel {
    var members: [User] = []
    var selectedStatus: UserStatusFilter = .all
    var isLoading: Bool = true
    var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()
    private let groupService: any GroupServiceProtocol
    private let challengeService: any ChallengeServiceProtocol

    private var latestChallenges: [Challenge] = []

    enum UserStatusFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case active = "Active"
        case inactive = "Inactive"

        var id: String { self.rawValue }
    }

    init(
        groupService: any GroupServiceProtocol,
        challengeService: any ChallengeServiceProtocol
    ) {
        self.groupService = groupService
        self.challengeService = challengeService
        addSubscribers()
    }

    private func addSubscribers() {
        groupService.currentGroup
            .receive(on: DispatchQueue.main)
            .map { $0.members }
            .sink { [weak self] returnedMembers in
                guard let self else { return }
                self.members = returnedMembers
                self.isLoading = false
            }
            .store(in: &cancellables)

        challengeService.challenges
            .receive(on: DispatchQueue.main)
            .sink { [weak self] challenges in
                self?.latestChallenges = challenges
            }
            .store(in: &cancellables)
    }

    var filteredMembers: [User] {
        switch selectedStatus {
        case .all:
            return members.sorted(by: { $0.currentEquity > $1.currentEquity })
        case .active:
            return members
                .filter { $0.status == .active }
                .sorted(by: { $0.currentEquity > $1.currentEquity })
        case .inactive:
            return members
                .filter { $0.status == .inactive || $0.status == .suspended }
                .sorted(by: { $0.currentEquity > $1.currentEquity })
        }
    }

    func isFrozen(member: User) -> Bool {
        ChallengeStakeCalculator.hasFrozenStake(for: member.id, in: latestChallenges)
    }

    func getFrozenAmount(for member: User) -> Decimal {
        ChallengeStakeCalculator.frozenAmount(for: member.id, in: latestChallenges)
    }
}
