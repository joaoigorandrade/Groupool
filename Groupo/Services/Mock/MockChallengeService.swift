// MockChallengeService.swift

import Combine
import Foundation

final class MockChallengeService: ChallengeServiceProtocol {

    // MARK: - State

    var challenges: AnyPublisher<[Challenge], Never> {
        store.$challenges.eraseToAnyPublisher()
    }

    var hasActiveChallenge: Bool {
        store.hasActiveChallenge
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
        store.challenges = store.challenges
    }

    func addChallenge(
        title: String,
        description: String,
        buyIn: Decimal,
        deadline: Date,
        validationMode: Challenge.ValidationMode
    ) async throws {
        guard !store.hasActiveChallenge else {
            throw ServiceError.activeChallengeExists
        }

        guard buyIn <= store.currentUserAvailableBalance else {
            throw ServiceError.insufficientFunds(
                available: store.currentUserAvailableBalance,
                required: buyIn
            )
        }

        var challenge = Challenge(
            id: UUID(),
            title: title,
            description: description,
            buyIn: buyIn,
            createdDate: Date(),
            deadline: deadline,
            participants: [store.currentUser.id],
            status: .active
        )
        challenge.validationMode = validationMode

        store.challenges.insert(challenge, at: 0)
        store.save()
    }

    func joinChallenge(id: UUID) async throws {
        guard let index = store.challenges.firstIndex(where: { $0.id == id }) else {
            throw ServiceError.challengeNotFound
        }

        var challenge = store.challenges[index]

        guard !challenge.participants.contains(store.currentUser.id) else {
            throw ServiceError.alreadyAParticipant
        }

        guard challenge.buyIn <= store.currentUserAvailableBalance else {
            throw ServiceError.insufficientFunds(
                available: store.currentUserAvailableBalance,
                required: challenge.buyIn
            )
        }

        challenge.participants.append(store.currentUser.id)
        store.challenges[index] = challenge
        store.save()
    }

    func submitProof(challengeID: UUID, imageData: Data?) async throws {
        guard let index = store.challenges.firstIndex(where: { $0.id == challengeID }) else {
            throw ServiceError.challengeNotFound
        }

        var challenge = store.challenges[index]

        guard challenge.status == .active else {
            throw ServiceError.invalidChallengeStatus(
                current: challenge.status,
                expected: .active
            )
        }

        challenge.proofImage = imageData?.base64EncodedString()
        challenge.proofSubmissionUserID = store.currentUser.id
        challenge.status = .voting

        store.challenges[index] = challenge
        store.save()
    }

    func startVoting(challengeID: UUID) async throws {
        guard let index = store.challenges.firstIndex(where: { $0.id == challengeID }) else {
            throw ServiceError.challengeNotFound
        }

        var challenge = store.challenges[index]

        guard challenge.status == .active else {
            throw ServiceError.invalidChallengeStatus(
                current: challenge.status,
                expected: .active
            )
        }

        challenge.status = .voting
        store.challenges[index] = challenge
        store.save()
    }

    func resolveVoting(challengeID: UUID) async throws {
        guard let index = store.challenges.firstIndex(where: { $0.id == challengeID }) else {
            throw ServiceError.challengeNotFound
        }

        var challenge = store.challenges[index]

        guard challenge.status == .voting else {
            throw ServiceError.invalidChallengeStatus(
                current: challenge.status,
                expected: .voting
            )
        }

        updateVotingParticipation(for: challengeID)

        let challengeVotes = store.votes.filter { $0.targetID == challengeID }
        let totalMembers = store.currentGroup.members.count

        if challengeVotes.isEmpty {
            challenge.status = .failed
            challenge.votingFailureReason = "No votes cast. Funds refunded."
            refundChallenge(challenge)
            store.challenges[index] = challenge
            store.save()
            return
        }

        let participationCount = challengeVotes.count
        let participationThreshold = Int(ceil(Double(totalMembers) * 0.5))

        if participationCount < participationThreshold {
            challenge.status = .failed
            challenge.votingFailureReason =
                "Insufficient participation (\(participationCount)/\(totalMembers)). Funds refunded."
            refundChallenge(challenge)
            store.challenges[index] = challenge
            store.save()
            return
        }

        let approvalVotes = challengeVotes.filter { $0.type == .approval }.count
        let contestVotes = challengeVotes.filter { $0.type == .contest }.count

        if approvalVotes == contestVotes {
            challenge.status = .failed
            challenge.votingFailureReason =
                "Tie vote (\(approvalVotes) vs \(contestVotes)). Funds refunded."
            refundChallenge(challenge)
            store.challenges[index] = challenge
            store.save()
            return
        }

        if approvalVotes > contestVotes {
            challenge.status = .complete

            let pot = challenge.buyIn * Decimal(challenge.participants.count)
            let winnerID = challenge.proofSubmissionUserID ?? store.currentUser.id

            if winnerID == store.currentUser.id {
                let profit = pot - challenge.buyIn
                store.updateUserStats(win: true, profit: profit)

                let winTransaction = Transaction(
                    id: UUID(),
                    description: "Vitoria: \(challenge.title)",
                    amount: profit,
                    type: .win,
                    timestamp: Date(),
                    relatedChallengeID: challenge.id,
                    splitDetails: nil
                )
                store.transactions.insert(winTransaction, at: 0)
            } else if challenge.participants.contains(store.currentUser.id) {
                store.updateUserStats(win: false, profit: 0, buyIn: challenge.buyIn)

                let lossTransaction = Transaction(
                    id: UUID(),
                    description: "Derrota: \(challenge.title)",
                    amount: challenge.buyIn,
                    type: .expense,
                    timestamp: Date(),
                    relatedChallengeID: challenge.id,
                    splitDetails: nil
                )
                store.transactions.insert(lossTransaction, at: 0)
            }
        } else {
            challenge.status = .failed
            challenge.votingFailureReason =
                "Challenge contested by majority. Funds refunded."
            refundChallenge(challenge)
        }

        store.challenges[index] = challenge
        store.save()
    }

    // MARK: - Private Helpers

    private func updateVotingParticipation(for targetID: UUID) {
        store.updateVotingParticipation(for: targetID)
    }


    private func refundChallenge(_ challenge: Challenge) {
        guard challenge.participants.contains(store.currentUser.id) else { return }

        let refundTransaction = Transaction(
            id: UUID(),
            description: "Reembolso: \(challenge.title)",
            amount: challenge.buyIn,
            type: .refund,
            timestamp: Date(),
            relatedChallengeID: challenge.id,
            splitDetails: nil
        )
        store.transactions.insert(refundTransaction, at: 0)
    }
}
