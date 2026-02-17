import Foundation
import Combine

class RequestWithdrawalViewModel: ObservableObject {
    @Published var amount: Decimal = 0
    @Published var dataService: MockDataService
    
    @Published var showCooldownAlert: Bool = false
    @Published var cooldownAlertMessage: String = ""
    
    init(dataService: MockDataService) {
        self.dataService = dataService
        self.amount = dataService.currentUserAvailableBalance
    }
    
    var isValid: Bool {
        return amount > 0 && amount <= dataService.currentUserAvailableBalance
    }
    
    private var hasRecentWin: Bool {
        let twentyFourHoursAgo = Date().addingTimeInterval(-24 * 60 * 60)
        return dataService.transactions.contains { transaction in
            transaction.type == .win && transaction.timestamp > twentyFourHoursAgo
        }
    }
    
    func submit() -> Bool {
        guard isValid else { return false }
        
        if hasRecentWin {
            cooldownAlertMessage = "Você ganhou um desafio nas últimas 24 horas. Aguarde o período de cooldown para sacar."
            showCooldownAlert = true
            return false
        }
        
        dataService.requestWithdrawal(amount: amount)
        return true
    }
}
