// WithdrawalServiceProtocol.swift

import Combine
import Foundation

protocol WithdrawalServiceProtocol {

    // MARK: - State

    var withdrawalRequests: AnyPublisher<[WithdrawalRequest], Never> { get }

    // MARK: - Actions

    func requestWithdrawal(amount: Decimal) async throws

    func verifyExpiredWithdrawals() async
}
