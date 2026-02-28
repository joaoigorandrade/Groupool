// MockUserService.swift

import Foundation

final class MockUserService: UserServiceProtocol {

    // MARK: - State

    var currentUser: User { store.currentUser }

    // MARK: - Private

    private let store: MockStore

    // MARK: - Init

    init(store: MockStore) {
        self.store = store
    }

    // MARK: - Actions

    func refresh() async {
        store.currentUser = store.currentUser
    }

    func updateUser(_ user: User) async throws {
        store.currentUser = user
        store.save()
    }

    func deposit(amount: Decimal) async throws {
        let newEquity = store.currentUser.currentEquity + amount

        let updatedUser = store.currentUser.updating(currentEquity: newEquity)
        store.currentUser = updatedUser

        var newMembers = store.currentGroup.members
        if let index = newMembers.firstIndex(where: { $0.id == updatedUser.id }) {
            newMembers[index] = updatedUser
        } else {
            newMembers.append(updatedUser)
        }

        let newTotalPool = store.currentGroup.totalPool + amount

        store.currentGroup = store.currentGroup.updating(
            totalPool: newTotalPool,
            members: newMembers
        )

        store.save()
    }
}
