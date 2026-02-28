// VoteServiceProtocol.swift

import Foundation

protocol VoteServiceProtocol: AnyObject {

    // MARK: - State

    var votes: [Vote] { get }

    // MARK: - Actions

    func castVote(targetID: UUID, type: Vote.VoteType) async throws

    func hasVoted(targetID: UUID, voterID: UUID) -> Bool
}
