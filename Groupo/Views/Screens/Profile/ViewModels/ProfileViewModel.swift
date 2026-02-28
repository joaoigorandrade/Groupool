import Foundation
import Observation
import SwiftUI

@Observable
final class ProfileViewModel {
    // MARK: - State
    var user: User
    var pixKeys: [PIXKey] = []
    var errorMessage: String?
    var showingAddKeySheet = false

    // MARK: - Dependencies
    private let userService: any UserServiceProtocol
    private let pixService: any PIXServiceProtocol

    init(userService: any UserServiceProtocol, pixService: any PIXServiceProtocol) {
        self.userService = userService
        self.pixService = pixService
        self.user = userService.currentUser
        loadPIXKeys()
    }

    private func loadPIXKeys() {
        Task { @MainActor in
            let keys = await pixService.fetchKeys()
            self.pixKeys = keys
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
