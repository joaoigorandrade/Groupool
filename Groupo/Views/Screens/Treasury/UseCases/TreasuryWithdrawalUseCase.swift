import Combine
import Foundation

protocol TreasuryWithdrawalUseCaseProtocol {
    var withdrawalRequests: AnyPublisher<[WithdrawalRequest], Never> { get }
    func verifyExpiredWithdrawals() async
}

final class TreasuryWithdrawalUseCase: TreasuryWithdrawalUseCaseProtocol {
    private let withdrawalService: any WithdrawalServiceProtocol
    
    init(withdrawalService: any WithdrawalServiceProtocol) {
        self.withdrawalService = withdrawalService
    }
    
    var withdrawalRequests: AnyPublisher<[WithdrawalRequest], Never> {
        withdrawalService.withdrawalRequests
    }
    
    func verifyExpiredWithdrawals() async {
        await withdrawalService.verifyExpiredWithdrawals()
    }
}
