import Combine
import Foundation

protocol TreasuryTransactionUseCaseProtocol {
    var transactions: AnyPublisher<[Transaction], Never> { get }
}

final class TreasuryTransactionUseCase: TreasuryTransactionUseCaseProtocol {
    private let transactionService: any TransactionServiceProtocol
    
    init(transactionService: any TransactionServiceProtocol) {
        self.transactionService = transactionService
    }
    
    var transactions: AnyPublisher<[Transaction], Never> {
        transactionService.transactions
    }
}
