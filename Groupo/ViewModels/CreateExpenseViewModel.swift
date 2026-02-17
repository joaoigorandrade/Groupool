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
    
    @Published var descriptionError: String? = nil
    @Published var amountError: String? = nil
    
    @Published var splitAmounts: [UUID: Double] = [:]
    
    @Published var isLoading: Bool = false
    
    private var subscribers = Set<AnyCancellable>()
    
    init() {
        setupValidation()
    }
    
    private func setupValidation() {
        $description
            .dropFirst()
            .sink { [weak self] _ in self?.validateDescription() }
            .store(in: &subscribers)
        
        $amount
            .dropFirst()
            .sink { [weak self] _ in self?.validateAmount() }
            .store(in: &subscribers)
    }
    
    private func validateDescription() {
        if description.isEmpty {
            descriptionError = "Required"
        } else if description.count > 50 {
            descriptionError = "Max 50 chars"
        } else {
            descriptionError = nil
        }
    }
    
    private func validateAmount() {
        if amount <= 0 {
            amountError = "Must be > 0"
        } else {
            amountError = nil
        }
    }
    
    var isValid: Bool {
        return descriptionError == nil &&
               amountError == nil &&
               !description.isEmpty &&
               amount > 0 &&
               errorMessage == nil // Checks custom split balance
    }
    
    var remainingAmount: Double {
        let totalAllocated = splitAmounts.values.reduce(0, +)
        return amount - totalAllocated
    }
    
    func validate(availableBalance: Decimal) -> Bool {
        validateDescription()
        validateAmount()
        
        let amountDecimal = Decimal(amount)
        if amountDecimal > availableBalance {
            amountError = "Insufficient funds"
            return false
        }
        
        if selectedSplit == .custom {
             if abs(remainingAmount) >= 0.01 {
                 errorMessage = "Total split must equal expense amount."
                 return false
             }
        }
        
        errorMessage = nil
        return isValid
    }
    
    func initializeSplits(members: [User]) {
        // Initialize with 0 or distribute evenly?
        // Let's distribute evenly initially for better UX
        distributeEvenly(members: members)
    }
    
    func distributeEvenly(members: [User]) {
        guard !members.isEmpty, amount > 0 else {
            // Reset if no amount or members
             members.forEach { splitAmounts[$0.id] = 0 }
            return
        }
        
        // Handle cents distribution
        let totalCents = Int(round(amount * 100))
        let count = members.count
        let baseCents = totalCents / count
        let remainderCents = totalCents % count
        
        for (index, member) in members.enumerated() {
            let cents = baseCents + (index < remainderCents ? 1 : 0)
            splitAmounts[member.id] = Double(cents) / 100.0
        }
    }
    
    @MainActor
    func createExpense(service: MockDataService, onSuccess: @escaping () -> Void) {
        let amountDecimal = Decimal(amount)
        guard validate(availableBalance: service.currentUserAvailableBalance) else { return }
        
        isLoading = true
        
        // Prepare split details if custom
        var splitDetails: [String: Decimal]? = nil
        if selectedSplit == .custom {
            var details: [String: Decimal] = [:]
            for (userId, splitAmount) in splitAmounts {
                if let user = service.currentGroup.members.first(where: { $0.id == userId }) {
                    details[user.name] = Decimal(splitAmount)
                }
            }
            // Explicitly set Equal Split logic if we want to save it as splits too?
            // Requirement says "Save custom split data". 
            // If equal, usually we don't need to save explicit splits unless requested.
            // But let's stick to custom only for now as per requirement.
            splitDetails = details
        } else {
             // For equal split, we can also generate details if we want consistency,
             // or leave nil to imply equal. Leaving nil is standard for "default" behavior.
             // But let's calculate it to be precise if the backend/model needs it.
             // The prompt says "Save custom split data".
             // I'll stick to saving it only when .custom is selected.
        }
        
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            service.addExpense(amount: amountDecimal, description: description, splitDetails: splitDetails)
            HapticManager.notificationSuccess()
            
            isLoading = false
            onSuccess()
        }
    }
}
