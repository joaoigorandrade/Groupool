import Foundation
import Observation

@Observable
class CreateChallengeViewModel {
    var title: String = "" {
        didSet { validateTitle() }
    }
    var description: String = "" {
        didSet { validateDescription() }
    }
    var buyInAmount: Decimal = 0.0 {
        didSet { validateAmount() }
    }
    var deadline: Date = Date() {
        didSet { validateDate() }
    }
    var validationMode: Challenge.ValidationMode = .proof

    var titleError: String? = nil
    var descriptionError: String? = nil
    var amountError: String? = nil
    var dateError: String? = nil

    var isLoading: Bool = false
    var errorMessage: String?

    private let challengeService: any ChallengeServiceProtocol
    private let userService: any UserServiceProtocol
    private let groupService: any GroupServiceProtocol

    private var currentUser: User?
    private var currentGroup: Group?
    private var latestChallenges: [Challenge] = []

    init(
        challengeService: any ChallengeServiceProtocol,
        userService: any UserServiceProtocol,
        groupService: any GroupServiceProtocol
    ) {
        self.challengeService = challengeService
        self.userService = userService
        self.groupService = groupService
        self.deadline = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        syncState()
    }

    // MARK: - State Sync

    private func syncState() {
        currentUser = userService.currentUser
        currentGroup = groupService.currentGroup
        latestChallenges = challengeService.challenges
    }

    // MARK: - Validation

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

    // MARK: - Computed Properties

    var projectedPrizePool: Decimal {
        let memberCount = Decimal(currentGroup?.members.count ?? 0)
        return buyInAmount * memberCount
    }

    var isStep1Valid: Bool {
        return titleError == nil &&
               descriptionError == nil &&
               dateError == nil &&
               !title.isEmpty &&
               !description.isEmpty &&
               deadline > Date()
    }

    var isValid: Bool {
        return isStep1Valid &&
               amountError == nil &&
               buyInAmount > 0
    }

    var activeChallenge: Challenge? {
        return latestChallenges.first { $0.status == .active || $0.status == .voting }
    }

    var activeChallengeRemainingTime: String {
        guard let challenge = activeChallenge else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: challenge.deadline, relativeTo: Date())
    }

    var canCreateChallenge: Bool {
        return !challengeService.hasActiveChallenge
    }

    var availableBalance: Decimal {
        guard let user = currentUser else { return 0 }
        let frozenBalance = latestChallenges
            .filter { ($0.status == .active || $0.status == .voting) && $0.participants.contains(user.id) }
            .reduce(0) { $0 + $1.buyIn }
        return user.currentEquity - frozenBalance
    }

    // MARK: - Actions

    @MainActor
    func createChallenge(completion: @escaping (Bool, String?) -> Void) {
        syncState()

        if challengeService.hasActiveChallenge {
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
            do {
                try await challengeService.addChallenge(
                    title: title,
                    description: description,
                    buyIn: buyInAmount,
                    deadline: deadline,
                    validationMode: validationMode
                )
                HapticManager.notificationSuccess()
                isLoading = false
                completion(true, nil)
            } catch {
                isLoading = false
                let message = error.localizedDescription
                errorMessage = message
                completion(false, message)
            }
        }
    }
}
