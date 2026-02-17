import Foundation
import Combine

class RequestWithdrawalViewModel: ObservableObject {
    @Published var amount: Decimal = 0
    @Published var dataService: MockDataService
    
    init(dataService: MockDataService) {
        self.dataService = dataService
        self.amount = dataService.currentUserAvailableBalance
    }
    
    var isValid: Bool {
        return amount > 0 && amount <= dataService.currentUserAvailableBalance
    }
    
    func submit() {
        guard isValid else { return }
        dataService.requestWithdrawal(amount: amount)
    }
}
