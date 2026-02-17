import SwiftUI
import Combine

class ProfileViewModel: ObservableObject {
    @Published var user: User
    private var dataService: MockDataService
    private var cancellables = Set<AnyCancellable>()
    
    init(dataService: MockDataService = MockDataService()) {
        self.dataService = dataService
        self.user = dataService.currentUser
        
        // Subscribe to changes in the data service
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
