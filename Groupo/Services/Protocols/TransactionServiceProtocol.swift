// TransactionServiceProtocol.swift

import Foundation

protocol TransactionServiceProtocol: AnyObject {

    // MARK: - State

    var transactions: [Transaction] { get }

    // MARK: - Actions

    func refresh() async

    func addExpense(
        amount: Decimal,
        description: String,
        splitDetails: [String: Decimal]?
    ) async throws
}
