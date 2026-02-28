import Foundation
import Observation

@Observable
class CreateExpenseViewModel {
    enum SplitOption: String, CaseIterable, Identifiable {
        case equal = "Equal Split"
        case custom = "Custom Split"

        var id: String { self.rawValue }
    }

    var description: String = "" {
        didSet { validateDescription() }
    }
    var amount: Double = 0.0 {
        didSet { validateAmount() }
    }
    var selectedSplit: SplitOption = .equal
    var errorMessage: String? = nil

    var descriptionError: String? = nil
    var amountError: String? = nil

    var splitAmounts: [UUID: Double] = [:]

    var isLoading: Bool = false

    private let transactionService: any TransactionServiceProtocol
    private let groupService: any GroupServiceProtocol

    var currentGroup: Group?

    init(
        transactionService: any TransactionServiceProtocol,
        groupService: any GroupServiceProtocol
    ) {
        self.transactionService = transactionService
        self.groupService = groupService
        syncState()
    }

    // MARK: - State Sync

    private func syncState() {
        currentGroup = groupService.currentGroup
    }

    // MARK: - Validation

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
               errorMessage == nil
    }

    var remainingAmount: Double {
        let totalAllocated = splitAmounts.values.reduce(0, +)
        return amount - totalAllocated
    }

    private var availableBalance: Decimal {
        guard let group = currentGroup else { return 0 }
        return group.totalPool
    }

    var currentGroupBalance: Decimal {
        return currentGroup?.totalPool ?? 0
    }

    var currentGroupMembers: [User] {
        return currentGroup?.members ?? []
    }

    func validate() -> Bool {
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
        distributeEvenly(members: members)
    }

    func distributeEvenly(members: [User]) {
        guard !members.isEmpty, amount > 0 else {
            members.forEach { splitAmounts[$0.id] = 0 }
            return
        }

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
    func createExpense(onSuccess: @escaping () -> Void) {
        guard validate() else { return }

        isLoading = true

        let amountDecimal = Decimal(amount)
        let desc = description

        // Transform split amounts from [UUID: Double] to [String: Decimal]
        var splitDetails: [String: Decimal]?
        if selectedSplit == .custom {
            splitDetails = splitAmounts.reduce(into: [:]) { result, pair in
                result[pair.key.uuidString] = Decimal(pair.value)
            }
        }

        Task {
            do {
                try await transactionService.addExpense(
                    amount: amountDecimal,
                    description: desc,
                    splitDetails: splitDetails
                )
                HapticManager.notificationSuccess()
                isLoading = false
                onSuccess()
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
