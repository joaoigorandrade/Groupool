// WithdrawalServiceProtocol.swift

import Foundation

protocol WithdrawalServiceProtocol: AnyObject {

    // MARK: - State

    var withdrawalRequests: [WithdrawalRequest] { get }

    // MARK: - Actions

    func requestWithdrawal(amount: Decimal) async throws

    func verifyExpiredWithdrawals() async
}
