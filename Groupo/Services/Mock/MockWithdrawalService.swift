// MockWithdrawalService.swift

import Combine
import Foundation

final class MockWithdrawalService: WithdrawalServiceProtocol {

    // MARK: - State

    var withdrawalRequests: AnyPublisher<[WithdrawalRequest], Never> {
        store.$withdrawalRequests.eraseToAnyPublisher()
    }

    // MARK: - Private

    private let store: MockStore

    // MARK: - Init

    init(store: MockStore) {
        self.store = store
    }

    // MARK: - Actions

    func requestWithdrawal(amount: Decimal) async throws {
        // Cooldown check: 24h since last win
        if let lastWin = store.currentUser.lastWinTimestamp {
            let cooldownEnd = lastWin.addingTimeInterval(60 * 60 * 24)
            let now = Date()
            if cooldownEnd > now {
                let remaining = cooldownEnd.timeIntervalSince(now)
                throw ServiceError.withdrawalCooldownActive(remaining: remaining)
            }
        }

        guard amount > 0, amount <= store.currentUserAvailableBalance else {
            throw ServiceError.insufficientFunds(
                available: store.currentUserAvailableBalance,
                required: amount
            )
        }

        let request = WithdrawalRequest(
            id: UUID(),
            initiatorID: store.currentUser.id,
            amount: amount,
            status: .pending,
            createdDate: Date(),
            deadline: Date().addingTimeInterval(60 * 60 * 24)
        )
        store.withdrawalRequests.insert(request, at: 0)
        store.save()
    }

    func verifyExpiredWithdrawals() async {
        let now = Date()
        let expiredPending = store.withdrawalRequests.filter {
            $0.status == .pending && $0.deadline < now
        }

        for request in expiredPending {
            autoApproveOrReject(request)
        }
    }

    // MARK: - Private Helpers

    private func autoApproveOrReject(_ request: WithdrawalRequest) {
        guard let index = store.withdrawalRequests.firstIndex(where: {
            $0.id == request.id
        }) else { return }

        let requestVotes = store.votes.filter { $0.targetID == request.id }
        let contestVotes = requestVotes.filter { $0.type == .contest }.count
        let totalMembers = store.currentGroup.members.count
        let requiredContestVotes = (totalMembers / 2) + 1

        if contestVotes < requiredContestVotes {
            // Auto-approve
            var updatedRequest = request
            updatedRequest.status = .approved
            store.withdrawalRequests[index] = updatedRequest

            updateVotingParticipation(for: request.id)

            // Deduct from pool
            let newPool = store.currentGroup.totalPool - request.amount
            store.currentGroup = Group(
                id: store.currentGroup.id,
                name: store.currentGroup.name,
                totalPool: newPool,
                members: store.currentGroup.members
            )

            // Deduct from member equity
            if let userIndex = store.currentGroup.members.firstIndex(where: {
                $0.id == request.initiatorID
            }) {
                let member = store.currentGroup.members[userIndex]
                let updatedMember = User(
                    id: member.id,
                    name: member.name,
                    avatar: member.avatar,
                    reputationScore: member.reputationScore,
                    currentEquity: member.currentEquity - request.amount,
                    challengesWon: member.challengesWon,
                    challengesLost: member.challengesLost,
                    lastWinTimestamp: member.lastWinTimestamp,
                    votingHistory: member.votingHistory,
                    consecutiveMissedVotes: member.consecutiveMissedVotes,
                    status: member.status
                )

                var newMembers = store.currentGroup.members
                newMembers[userIndex] = updatedMember

                store.currentGroup = Group(
                    id: store.currentGroup.id,
                    name: store.currentGroup.name,
                    totalPool: store.currentGroup.totalPool,
                    members: newMembers
                )

                if updatedMember.id == store.currentUser.id {
                    store.currentUser = updatedMember
                }
            }

            let transaction = Transaction(
                id: UUID(),
                description: "Withdrawal Approved (Auto)",
                amount: request.amount,
                type: .withdrawal,
                timestamp: Date(),
                relatedChallengeID: nil,
                splitDetails: nil
            )
            store.transactions.insert(transaction, at: 0)
            store.save()
        } else {
            // Reject
            var updatedRequest = request
            updatedRequest.status = .rejected
            store.withdrawalRequests[index] = updatedRequest
            store.save()
        }
    }

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
}
