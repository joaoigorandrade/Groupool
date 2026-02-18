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

        // Edge Case: No votes cast
        if challengeVotes.isEmpty {
            challenge.status = .failed
            challenge.votingFailureReason = "No votes cast. Funds refunded."
            refundChallenge(challenge)
            store.challenges[index] = challenge
            store.save()
            return
        }

        // 50% participation threshold
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

        // Edge Case: Tie
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
                updateUserStats(win: true, profit: profit)

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
                updateUserStats(win: false, profit: 0, buyIn: challenge.buyIn)

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
        var newMembers = store.currentGroup.members

        for (memberIndex, member) in newMembers.enumerated() {
            let hasVoted = store.votes.contains {
                $0.targetID == targetID && $0.voterID == member.id
            }

            var newHistory = member.votingHistory
            var newConsecutive = member.consecutiveMissedVotes
            var newStatus = member.status

            if hasVoted {
                if !newHistory.contains(targetID) {
                    newHistory.append(targetID)
                }
                newConsecutive = 0
            } else {
                newConsecutive += 1
                if newConsecutive >= 3 {
                    newStatus = .inactive
                }
            }

            newMembers[memberIndex] = User(
                id: member.id,
                name: member.name,
                avatar: member.avatar,
                reputationScore: member.reputationScore,
                currentEquity: member.currentEquity,
                challengesWon: member.challengesWon,
                challengesLost: member.challengesLost,
                lastWinTimestamp: member.lastWinTimestamp,
                votingHistory: newHistory,
                consecutiveMissedVotes: newConsecutive,
                status: newStatus
            )
        }

        store.currentGroup = Group(
            id: store.currentGroup.id,
            name: store.currentGroup.name,
            totalPool: store.currentGroup.totalPool,
            members: newMembers
        )

        if let updatedCurrentUser = newMembers.first(where: {
            $0.id == store.currentUser.id
        }) {
            store.currentUser = updatedCurrentUser
        }

        store.save()
    }

    private func updateUserStats(win: Bool, profit: Decimal, buyIn: Decimal = 0) {
        if win {
            store.currentUser = User(
                id: store.currentUser.id,
                name: store.currentUser.name,
                avatar: store.currentUser.avatar,
                reputationScore: store.currentUser.reputationScore + 10,
                currentEquity: store.currentUser.currentEquity + profit,
                challengesWon: store.currentUser.challengesWon + 1,
                challengesLost: store.currentUser.challengesLost,
                lastWinTimestamp: Date(),
                votingHistory: store.currentUser.votingHistory,
                consecutiveMissedVotes: store.currentUser.consecutiveMissedVotes,
                status: store.currentUser.status
            )
        } else {
            store.currentUser = User(
                id: store.currentUser.id,
                name: store.currentUser.name,
                avatar: store.currentUser.avatar,
                reputationScore: store.currentUser.reputationScore,
                currentEquity: store.currentUser.currentEquity - buyIn,
                challengesWon: store.currentUser.challengesWon,
                challengesLost: store.currentUser.challengesLost + 1,
                lastWinTimestamp: store.currentUser.lastWinTimestamp,
                votingHistory: store.currentUser.votingHistory,
                consecutiveMissedVotes: store.currentUser.consecutiveMissedVotes,
                status: store.currentUser.status
            )
        }
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
