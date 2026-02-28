import Foundation
import Observation

@Observable
class MemberListViewModel {
    var members: [User] = []
    var selectedStatus: UserStatusFilter = .all
    var isLoading: Bool = true
    var errorMessage: String?

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
        syncState()
    }

    // MARK: - State Sync

    private func syncState() {
        members = groupService.currentGroup.members
        latestChallenges = challengeService.challenges
        isLoading = false
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
