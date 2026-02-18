import SwiftUI
import Combine

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
    private var dataService: MockDataService?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        
    }
    
    func setup(service: MockDataService) {
        self.dataService = service
        setupSubscribers()
    }
    
    private func setupSubscribers() {
        guard let dataService = dataService else { return }
        dataService.$currentUser
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
