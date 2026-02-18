import Combine
import Foundation

class MemberListViewModel: ObservableObject {
    @Published var members: [User] = []
    @Published var filteredMembers: [User] = []
    @Published var selectedStatus: UserStatusFilter = .all
    @Published var isLoading: Bool = true
    @Published var errorMessage: String?

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
        // Simulate initial load
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run {
                addSubscribers()
                isLoading = false
            }
        }
    }

    private func addSubscribers() {
        groupService.currentGroup
            .receive(on: DispatchQueue.main)
            .map { $0.members }
            .sink { [weak self] returnedMembers in
                self?.members = returnedMembers
                self?.filterMembers()
            }
            .store(in: &cancellables)

        challengeService.challenges
            .receive(on: DispatchQueue.main)
            .sink { [weak self] challenges in
                self?.latestChallenges = challenges
            }
            .store(in: &cancellables)

        $selectedStatus
            .sink { [weak self] _ in
                self?.filterMembers()
            }
            .store(in: &cancellables)
    }

    private func filterMembers() {
        switch selectedStatus {
        case .all:
            filteredMembers = members.sorted(by: { $0.currentEquity > $1.currentEquity })
        case .active:
            filteredMembers = members
                .filter { $0.status == .active }
                .sorted(by: { $0.currentEquity > $1.currentEquity })
        case .inactive:
            filteredMembers = members
                .filter { $0.status == .inactive || $0.status == .suspended }
                .sorted(by: { $0.currentEquity > $1.currentEquity })
        }
    }

    func isFrozen(member: User) -> Bool {
        let activeChallenges = latestChallenges.filter {
            ($0.status == .active || $0.status == .voting) &&
            $0.participants.contains(member.id)
        }
        return !activeChallenges.isEmpty
    }

    func getFrozenAmount(for member: User) -> Decimal {
        let activeChallenges = latestChallenges.filter {
            ($0.status == .active || $0.status == .voting) &&
            $0.participants.contains(member.id)
        }
        return activeChallenges.reduce(0) { $0 + $1.buyIn }
    }
}
