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
            store.currentGroup = store.currentGroup.updating(totalPool: newPool)

            // Deduct from member equity
            if let userIndex = store.currentGroup.members.firstIndex(where: {
                $0.id == request.initiatorID
            }) {
                let member = store.currentGroup.members[userIndex]
                let updatedMember = member.updating(currentEquity: member.currentEquity - request.amount)

                var newMembers = store.currentGroup.members
                newMembers[userIndex] = updatedMember

                store.currentGroup = store.currentGroup.updating(members: newMembers)

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
        store.updateVotingParticipation(for: targetID)
    }
}
