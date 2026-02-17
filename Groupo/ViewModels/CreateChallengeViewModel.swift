import Foundation
import Combine

class CreateChallengeViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var buyInAmount: Decimal = 0.0
    @Published var deadline: Date = Date()

    
    @Published var isLoading: Bool = false
    
    private let dataService: MockDataService
    
    init(dataService: MockDataService) {
        self.dataService = dataService
        self.deadline = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    }
    
    var projectedPrizePool: Decimal {
        let memberCount = Decimal(dataService.currentGroup.members.count)
        return buyInAmount * memberCount
    }
    
    var isValid: Bool {
        return !title.isEmpty && !description.isEmpty && buyInAmount > 0
    }
    
    var activeChallenge: Challenge? {
        return dataService.activeChallenge
    }
    
    var activeChallengeRemainingTime: String {
        guard let challenge = activeChallenge else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: challenge.deadline, relativeTo: Date())
    }

    var canCreateChallenge: Bool {
        return !dataService.hasActiveChallenge
    }
    
    var availableBalance: Decimal {
        return dataService.currentUserAvailableBalance
    }
    
    @MainActor
    func createChallenge(completion: @escaping (Bool, String?) -> Void) {
        if dataService.hasActiveChallenge {
            completion(false, "Existe um desafio ativo. Aguarde o término para criar outro.")
            return
        }
        
        guard isValid else {
            completion(false, "Preencha todos os campos corretamente.")
            return
        }
        
        guard buyInAmount <= availableBalance else {
            completion(false, "Saldo insuficiente. Disponível: \(availableBalance.formatted(.currency(code: "BRL")))")
            return
        }
        
        isLoading = true
        
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            dataService.addChallenge(title: title, description: description, buyIn: buyInAmount, deadline: deadline)
            HapticManager.notificationSuccess()
            
            isLoading = false
            completion(true, nil)
        }
    }
}
