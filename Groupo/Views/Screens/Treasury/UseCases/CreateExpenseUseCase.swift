import Foundation

protocol CreateExpenseUseCaseProtocol {
    func createExpense(description: String, amount: Decimal, splitOption: CreateExpenseViewModel.SplitOption, splits: [UUID: Double]) async throws
}

final class CreateExpenseUseCase: CreateExpenseUseCaseProtocol {
    private let transactionService: any TransactionServiceProtocol
    
    init(transactionService: any TransactionServiceProtocol) {
        self.transactionService = transactionService
    }
    
    func createExpense(description: String, amount: Decimal, splitOption: CreateExpenseViewModel.SplitOption, splits: [UUID: Double]) async throws {
        // Map splits [UUID: Double] to [String: Decimal] as expected by TransactionService
        let splitDetails = splits.reduce(into: [String: Decimal]()) { dict, entry in
            dict[entry.key.uuidString] = Decimal(entry.value)
        }
        
        try await transactionService.addExpense(
            amount: amount,
            description: description,
            splitDetails: splitDetails
        )
    }
}
