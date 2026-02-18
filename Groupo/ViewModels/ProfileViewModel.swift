import Combine
import SwiftUI

class ProfileViewModel: ObservableObject {
    @Published var user: User = User(
        id: UUID(),
        name: "Loading...",
        avatar: "person.circle.fill",
        reputationScore: 0,
        currentEquity: 0,
        challengesWon: 0,
        challengesLost: 0,
        lastWinTimestamp: nil,
        votingHistory: [],
        consecutiveMissedVotes: 0,
        status: .active
    )
    @Published var errorMessage: String?

    private let userService: any UserServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(userService: any UserServiceProtocol) {
        self.userService = userService
        setupSubscribers()
    }

    private func setupSubscribers() {
        userService.currentUser
            .receive(on: DispatchQueue.main)
            .assign(to: \.user, on: self)
            .store(in: &cancellables)
    }

    var reliabilityScore: Double {
        let totalChallenges = user.challengesWon + user.challengesLost
        guard totalChallenges > 0 else { return 0.0 }
        return Double(user.challengesWon) / Double(totalChallenges)
    }

    var statusColor: Color {
        switch user.status {
        case .active:
            return .green
        case .inactive:
            return .gray
        case .suspended:
            return .red
        }
    }

    var statusText: String {
        switch user.status {
        case .active:
            return "Good Standing"
        case .inactive:
            return "Inactive"
        case .suspended:
            return "Restricted"
        }
    }
}
