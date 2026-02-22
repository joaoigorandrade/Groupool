import Foundation

protocol RequestWithdrawalUseCaseProtocol {
    func requestWithdrawal(amount: Decimal) async throws
}

final class RequestWithdrawalUseCase: RequestWithdrawalUseCaseProtocol {
    private let withdrawalService: any WithdrawalServiceProtocol
    
    init(withdrawalService: any WithdrawalServiceProtocol) {
        self.withdrawalService = withdrawalService
    }
    
    func requestWithdrawal(amount: Decimal) async throws {
        try await withdrawalService.requestWithdrawal(amount: amount)
    }
}
