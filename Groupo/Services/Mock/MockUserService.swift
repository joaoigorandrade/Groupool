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

    func updateUser(_ user: User) async throws {
        store.currentUser = user
        store.save()
    }
}
