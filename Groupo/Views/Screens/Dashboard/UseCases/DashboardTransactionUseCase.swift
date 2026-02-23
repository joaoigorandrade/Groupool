import Combine
import Foundation

protocol DashboardTransactionUseCaseProtocol {
    var transactions: AnyPublisher<[Transaction], Never> { get }
    func refresh() async
}

final class DashboardTransactionUseCase: DashboardTransactionUseCaseProtocol {
    private let transactionService: any TransactionServiceProtocol

    init(transactionService: any TransactionServiceProtocol) {
        self.transactionService = transactionService
    }

    var transactions: AnyPublisher<[Transaction], Never> {
        transactionService.transactions
    }

    func refresh() async {
        await transactionService.refresh()
    }
}
