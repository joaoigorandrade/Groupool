// ChallengeServiceProtocol.swift

import Foundation

protocol ChallengeServiceProtocol: AnyObject {

    // MARK: - State

    var challenges: [Challenge] { get }

    var hasActiveChallenge: Bool { get }

    // MARK: - Actions

    func refresh() async

    func addChallenge(
        title: String,
        description: String,
        buyIn: Decimal,
        deadline: Date,
        validationMode: Challenge.ValidationMode
    ) async throws

    func joinChallenge(id: UUID) async throws

    func submitProof(challengeID: UUID, imageData: Data?) async throws

    func startVoting(challengeID: UUID) async throws

    func resolveVoting(challengeID: UUID) async throws
}
