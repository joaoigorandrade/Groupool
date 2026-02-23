// MockUserService.swift

import Combine
import Foundation

final class MockUserService: UserServiceProtocol {

    // MARK: - State

    var currentUser: AnyPublisher<User, Never> {
        store.$currentUser.eraseToAnyPublisher()
    }

    // MARK: - Private

    private let store: MockStore

    // MARK: - Init

    init(store: MockStore) {
        self.store = store
    }

    // MARK: - Actions

    func refresh() async {
        // Re-assign to trigger downstream publishers.
        // Real implementations will fetch from the network here.
        store.currentUser = store.currentUser
    }

    func updateUser(_ user: User) async throws {
        store.currentUser = user
        store.save()
    }

    func deposit(amount: Decimal) async throws {
        let newEquity = store.currentUser.currentEquity + amount
        
        let updatedUser = User(
            id: store.currentUser.id,
            name: store.currentUser.name,
            avatar: store.currentUser.avatar,
            reputationScore: store.currentUser.reputationScore,
            currentEquity: newEquity,
            challengesWon: store.currentUser.challengesWon,
            challengesLost: store.currentUser.challengesLost,
            lastWinTimestamp: store.currentUser.lastWinTimestamp,
            votingHistory: store.currentUser.votingHistory,
            consecutiveMissedVotes: store.currentUser.consecutiveMissedVotes,
            status: store.currentUser.status
        )
        
        store.currentUser = updatedUser
        
        // 2. Add to group members and update pool
        var newMembers = store.currentGroup.members
        if let index = newMembers.firstIndex(where: { $0.id == updatedUser.id }) {
            newMembers[index] = updatedUser
        } else {
            newMembers.append(updatedUser)
        }
        
        let newTotalPool = store.currentGroup.totalPool + amount
        
        store.currentGroup = Group(
            id: store.currentGroup.id,
            name: store.currentGroup.name,
            totalPool: newTotalPool,
            members: newMembers
        )

        store.save()
    }
}
