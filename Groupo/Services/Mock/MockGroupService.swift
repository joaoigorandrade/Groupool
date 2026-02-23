// MockGroupService.swift

import Combine
import Foundation

final class MockGroupService: GroupServiceProtocol {

    // MARK: - State

    var currentGroup: AnyPublisher<Group, Never> {
        store.$currentGroup.eraseToAnyPublisher()
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
        store.currentGroup = store.currentGroup
    }
}
