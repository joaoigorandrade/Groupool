// VoteServiceProtocol.swift

import Combine
import Foundation

protocol VoteServiceProtocol {

    // MARK: - State

    var votes: AnyPublisher<[Vote], Never> { get }

    // MARK: - Actions

    func castVote(targetID: UUID, type: Vote.VoteType) async throws

    func hasVoted(targetID: UUID, voterID: UUID) -> Bool
}
