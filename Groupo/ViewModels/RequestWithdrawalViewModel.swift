import Foundation
import Combine

class RequestWithdrawalViewModel: ObservableObject {
    @Published var amount: Decimal = 0
    @Published var dataService: MockDataService
    
    @Published var showCooldownAlert: Bool = false
    @Published var cooldownAlertMessage: String = ""
    
    @Published var cooldownString: String? = nil
    private var timer: AnyCancellable?
    
    init(dataService: MockDataService) {
        self.dataService = dataService
        self.amount = dataService.currentUserAvailableBalance
        startCooldownTimer()
    }
    
    var isValid: Bool {
        return amount > 0 && amount <= dataService.currentUserAvailableBalance && cooldownString == nil
    }
    
    private func startCooldownTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateCooldownStatus()
            }
        updateCooldownStatus() // Initial check
    }
    
    private func updateCooldownStatus() {
        guard let lastWin = dataService.currentUser.lastWinTimestamp else {
            cooldownString = nil
            return
        }
        
        let cooldownDuration: TimeInterval = 24 * 60 * 60
        let timeSinceWin = Date().timeIntervalSince(lastWin)
        
        if timeSinceWin < cooldownDuration {
            let remaining = cooldownDuration - timeSinceWin
            let hours = Int(remaining) / 3600
            let minutes = Int(remaining) / 60 % 60
            let seconds = Int(remaining) % 60
            cooldownString = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            cooldownString = nil
            timer?.cancel()
            timer = nil
        }
    }
    
    func submit() -> Bool {
        guard isValid else { return false }
        
        if cooldownString != nil {
             cooldownAlertMessage = "Você ganhou um desafio nas últimas 24 horas. Aguarde o período de cooldown para sacar."
             showCooldownAlert = true
             return false
        }
        
        dataService.requestWithdrawal(amount: amount)
        return true
    }
}
