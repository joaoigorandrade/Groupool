import Foundation
import Combine

class CreateChallengeViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var buyInAmount: Decimal = 0.0
    @Published var deadline: Date = Date()
    @Published var validationMode: Challenge.ValidationMode = .proof

    
    @Published var titleError: String? = nil
    @Published var descriptionError: String? = nil
    @Published var amountError: String? = nil
    @Published var dateError: String? = nil
    
    @Published var isLoading: Bool = false
    
    private let dataService: MockDataService
    private var subscribers = Set<AnyCancellable>()
    
    init(dataService: MockDataService) {
        self.dataService = dataService
        self.deadline = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        setupValidation()
    }
    
    private func setupValidation() {
        $title
            .dropFirst()
            .sink { [weak self] _ in self?.validateTitle() }
            .store(in: &subscribers)
        
        $description
            .dropFirst()
            .sink { [weak self] _ in self?.validateDescription() }
            .store(in: &subscribers)
            
        $buyInAmount
            .dropFirst()
            .sink { [weak self] _ in self?.validateAmount() }
            .store(in: &subscribers)
            
        $deadline
            .dropFirst()
            .sink { [weak self] _ in self?.validateDate() }
            .store(in: &subscribers)
    }
    
    private func validateTitle() {
        if title.isEmpty {
            titleError = "O título é obrigatório."
        } else if title.count > 50 {
            titleError = "O título deve ter no máximo 50 caracteres."
        } else {
            titleError = nil
        }
    }
    
    private func validateDescription() {
        if description.isEmpty {
            descriptionError = "A descrição é obrigatória."
        } else if description.count > 200 {
            descriptionError = "A descrição deve ter no máximo 200 caracteres."
        } else {
            descriptionError = nil
        }
    }
    
    private func validateAmount() {
        if buyInAmount <= 0 {
            amountError = "O valor deve ser maior que zero."
        } else if buyInAmount > availableBalance {
            amountError = "Saldo insuficiente."
        } else {
            amountError = nil
        }
    }
    
    private func validateDate() {
        if deadline <= Date() {
            dateError = "A data deve ser futura."
        } else {
            dateError = nil
        }
    }
    
    var projectedPrizePool: Decimal {
        let memberCount = Decimal(dataService.currentGroup.members.count)
        return buyInAmount * memberCount
    }
    
    var isValid: Bool {
        // Trigger all validations to ensure state is correct before final check
        // Although subscribers handle real-time, this is a safe check
        return titleError == nil &&
               descriptionError == nil &&
               amountError == nil &&
               dateError == nil &&
               !title.isEmpty &&
               !description.isEmpty &&
               buyInAmount > 0 &&
               deadline > Date()
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
        
        validateTitle()
        validateDescription()
        validateAmount()
        validateDate()
        
        guard isValid else {
            completion(false, "Verifique os erros no formulário.")
            return
        }
        
        guard buyInAmount <= availableBalance else {
            completion(false, "Saldo insuficiente. Disponível: \(availableBalance.formatted(.currency(code: "BRL")))")
            return
        }
        
        isLoading = true
        
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            dataService.addChallenge(
                title: title, 
                description: description, 
                buyIn: buyInAmount, 
                deadline: deadline,
                validationMode: validationMode
            )
            HapticManager.notificationSuccess()
            
            isLoading = false
            completion(true, nil)
        }
    }
}
