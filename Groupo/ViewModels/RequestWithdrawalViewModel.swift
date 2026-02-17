import Foundation
import Combine

class RequestWithdrawalViewModel: ObservableObject {
    @Published var amount: Decimal = 0
    @Published var amountError: String? = nil
    
    @Published var dataService: MockDataService
    
    @Published var cooldownString: String? = nil
    private var timer: AnyCancellable?
    private var subscribers = Set<AnyCancellable>()
    
    init(dataService: MockDataService) {
        self.dataService = dataService
        self.amount = dataService.currentUserAvailableBalance
        startCooldownTimer()
        setupValidation()
    }
    
    private func setupValidation() {
        $amount
            .dropFirst()
            .sink { [weak self] _ in self?.validateAmount() }
            .store(in: &subscribers)
    }
    
    private func validateAmount() {
        if amount <= 0 {
            amountError = "O valor deve ser maior que zero."
        } else if amount > dataService.currentUserAvailableBalance {
            amountError = "Saldo insuficiente."
        } else {
            amountError = nil
        }
    }
    
    var isValid: Bool {
        return amount > 0 && 
               amount <= dataService.currentUserAvailableBalance && 
               cooldownString == nil &&
               amountError == nil
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
    
    @Published var isLoading: Bool = false
    
    // ... (existing code)
    
    @MainActor
    func submit(completion: @escaping (Bool, String?) -> Void) {
        validateAmount()
        
        guard isValid else {
            completion(false, amountError ?? "Verifique os erros.")
            return
        }
        
        if cooldownString != nil {
             completion(false, "Você ganhou um desafio nas últimas 24 horas. Aguarde o período de cooldown para sacar.")
             return
        }
        
        isLoading = true
        
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            dataService.requestWithdrawal(amount: amount)
            HapticManager.notificationSuccess()
            
            isLoading = false
            completion(true, nil)
        }
    }
}
