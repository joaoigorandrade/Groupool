// TransactionServiceProtocol.swift

import Combine
import Foundation

protocol TransactionServiceProtocol {

    // MARK: - State

    var transactions: AnyPublisher<[Transaction], Never> { get }

    // MARK: - Actions

    func addExpense(
        amount: Decimal,
        description: String,
        splitDetails: [String: Decimal]?
    ) async throws
}
