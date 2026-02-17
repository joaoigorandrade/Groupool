import Foundation
import Combine

class CreateChallengeViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var buyInAmount: Decimal = 0.0
    @Published var deadline: Date = Date()
    @Published var errorMessage: String?
    
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
    
    func createChallenge(completion: @escaping (Bool) -> Void) {
        if dataService.hasActiveChallenge {
            errorMessage = "Já existe um desafio ativo neste grupo."
            completion(false)
            return
        }
        
        guard isValid else {
            errorMessage = "Preencha todos os campos corretamente."
            completion(false)
            return
        }
        
        dataService.addChallenge(title: title, description: description, buyIn: buyInAmount, deadline: deadline)
        completion(true)
    }
}
