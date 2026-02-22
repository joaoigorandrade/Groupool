import Observation
import Foundation
import Combine

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

    private let createExpenseUseCase: CreateExpenseUseCaseProtocol
    private let groupService: any GroupServiceProtocol
    private var subscribers = Set<AnyCancellable>()

    var currentGroup: Group?

    init(
        createExpenseUseCase: CreateExpenseUseCaseProtocol,
        groupService: any GroupServiceProtocol
    ) {
        self.createExpenseUseCase = createExpenseUseCase
        self.groupService = groupService
        setupSubscribers()
    }

    // MARK: - Subscribers

    private func setupSubscribers() {
        groupService.currentGroup
            .receive(on: DispatchQueue.main)
            .sink { [weak self] group in
                self?.currentGroup = group
            }
            .store(in: &subscribers)
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

        Task {
            do {
                try await createExpenseUseCase.createExpense(
                    description: desc,
                    amount: amountDecimal,
                    splitOption: selectedSplit,
                    splits: splitAmounts
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
