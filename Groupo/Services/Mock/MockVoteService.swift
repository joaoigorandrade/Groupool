// MockVoteService.swift

import Combine
import Foundation

final class MockVoteService: VoteServiceProtocol {

    // MARK: - State

    var votes: AnyPublisher<[Vote], Never> {
        store.$votes.eraseToAnyPublisher()
    }

    // MARK: - Private

    private let store: MockStore

    // MARK: - Init

    init(store: MockStore) {
        self.store = store
    }

    // MARK: - Actions

    func castVote(targetID: UUID, type: Vote.VoteType) async throws {
        let voterID = store.currentUser.id

        // Remove existing vote for same (targetID, voterID) pair
        if let existingIndex = store.votes.firstIndex(where: {
            $0.targetID == targetID && $0.voterID == voterID
        }) {
            store.votes.remove(at: existingIndex)
        }

        let vote = Vote(
            id: UUID(),
            voterID: voterID,
            targetID: targetID,
            type: type,
            deadline: Date().addingTimeInterval(60 * 60 * 24)
        )
        store.votes.append(vote)
        store.save()
    }

    func hasVoted(targetID: UUID, voterID: UUID) -> Bool {
        store.votes.contains { $0.targetID == targetID && $0.voterID == voterID }
    }
}
