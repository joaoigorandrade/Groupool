import Foundation
import Combine

class CreateExpenseViewModel: ObservableObject {
    enum SplitOption: String, CaseIterable, Identifiable {
        case equal = "Equal Split"
        case custom = "Custom Split"
        
        var id: String { self.rawValue }
    }
    
    @Published var description: String = ""
    @Published var amount: Double = 0.0
    @Published var selectedSplit: SplitOption = .equal
    @Published var errorMessage: String? = nil
    
    var isValid: Bool {
        return !description.isEmpty && amount > 0
    }
    
    func validate(availableBalance: Decimal) -> Bool {
        let amountDecimal = Decimal(amount)
        if amountDecimal > availableBalance {
            errorMessage = "Insufficient funds. Available: \(availableBalance.formatted(.currency(code: "BRL")))"
            return false
        }
        errorMessage = nil
        return true
    }
    
    func createExpense(service: MockDataService, onSuccess: () -> Void) {
        guard validate(availableBalance: service.currentUserAvailableBalance) else { return }
        
        service.addExpense(amount: Decimal(amount), description: description)
        onSuccess()
    }
}
