import Combine
import Foundation
import Observation
import SwiftUI

@Observable
final class ProfileViewModel {
    // MARK: - State
    var user: User = User(
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
    var pixKeys: [PIXKey] = []
    var errorMessage: String?
    var showingAddKeySheet = false
    
    // MARK: - Dependencies
    private let profileUseCase: ProfileUseCaseProtocol
    private let pixUseCase: PIXUseCaseProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    init(profileUseCase: ProfileUseCaseProtocol, pixUseCase: PIXUseCaseProtocol) {
        self.profileUseCase = profileUseCase
        self.pixUseCase = pixUseCase
        setupSubscribers()
        loadPIXKeys()
    }
    
    private func setupSubscribers() {
        profileUseCase.currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.user = user
            }
            .store(in: &cancellables)
    }
    
    private func loadPIXKeys() {
        Task {
            let keys = await pixUseCase.fetchKeys()
            await MainActor.run {
                self.pixKeys = keys
            }
        }
    }
    
    // MARK: - Actions
    
    func deletePIXKey(at offsets: IndexSet) {
        pixKeys.remove(atOffsets: offsets)
    }
    
    func addPIXKey(type: PIXKey.PIXKeyType, value: String) {
        let newKey = PIXKey(id: UUID(), type: type, value: value)
        pixKeys.append(newKey)
        showingAddKeySheet = false
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    // MARK: - Computed Properties
    
    var reliabilityScore: Double {
        let totalChallenges = user.challengesWon + user.challengesLost
        guard totalChallenges > 0 else { return 0.0 }
        return Double(user.challengesWon) / Double(totalChallenges)
    }

    var statusColor: Color {
        switch user.status {
        case .active: return .green
        case .inactive: return .gray
        case .suspended: return .red
        }
    }

    var statusText: String {
        switch user.status {
        case .active: return "Good Standing"
        case .inactive: return "Inactive"
        case .suspended: return "Restricted"
        }
    }
}
