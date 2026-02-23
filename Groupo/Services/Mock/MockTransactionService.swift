// MockTransactionService.swift

import Combine
import Foundation

final class MockTransactionService: TransactionServiceProtocol {

    // MARK: - State

    var transactions: AnyPublisher<[Transaction], Never> {
        store.$transactions.eraseToAnyPublisher()
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
        store.transactions = store.transactions
    }

    func addExpense(
        amount: Decimal,
        description: String,
        splitDetails: [String: Decimal]?
    ) async throws {
        guard amount <= store.currentUserAvailableBalance else {
            throw ServiceError.insufficientFunds(
                available: store.currentUserAvailableBalance,
                required: amount
            )
        }

        let transaction = Transaction(
            id: UUID(),
            description: description,
            amount: amount,
            type: .expense,
            timestamp: Date(),
            relatedChallengeID: nil,
            splitDetails: splitDetails
        )
        store.transactions.insert(transaction, at: 0)

        let newPool = store.currentGroup.totalPool - amount
        store.currentGroup = Group(
            id: store.currentGroup.id,
            name: store.currentGroup.name,
            totalPool: newPool,
            members: store.currentGroup.members
        )

        store.save()
    }
}
