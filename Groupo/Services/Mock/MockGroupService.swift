// MockGroupService.swift

import Foundation

final class MockGroupService: GroupServiceProtocol {

    // MARK: - State

    var currentGroup: Group { store.currentGroup }

    // MARK: - Private

    private let store: MockStore

    // MARK: - Init

    init(store: MockStore) {
        self.store = store
    }

    // MARK: - Actions

    func refresh() async {
        store.currentGroup = store.currentGroup
    }
}
