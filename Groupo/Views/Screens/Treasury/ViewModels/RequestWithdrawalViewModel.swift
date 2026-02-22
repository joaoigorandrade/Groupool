import Combine
import Foundation

@Observable
class RequestWithdrawalViewModel {
    var amount: Decimal = 0 {
        didSet { validateAmount() }
    }
    var amountError: String? = nil
    var cooldownString: String? = nil
    var isLoading: Bool = false
    var errorMessage: String?
    private(set) var availableBalance: Decimal = 0

    private let requestWithdrawalUseCase: RequestWithdrawalUseCaseProtocol
    private let userService: any UserServiceProtocol

    private var currentUser: User?
    private var timer: AnyCancellable?
    private var subscribers = Set<AnyCancellable>()

    init(
        requestWithdrawalUseCase: RequestWithdrawalUseCaseProtocol,
        userService: any UserServiceProtocol
    ) {
        self.requestWithdrawalUseCase = requestWithdrawalUseCase
        self.userService = userService
        setupSubscribers()
        startCooldownTimer()
    }

    // MARK: - Subscribers

    private func setupSubscribers() {
        userService.currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                guard let self else { return }
                let isFirstLoad = currentUser == nil
                currentUser = user
                availableBalance = user.currentEquity
                if isFirstLoad {
                    amount = availableBalance
                }
                updateCooldownStatus()
            }
            .store(in: &subscribers)
    }

    // MARK: - Validation

    private func validateAmount() {
        if amount <= 0 {
            amountError = "O valor deve ser maior que zero."
        } else if amount > availableBalance {
            amountError = "Saldo insuficiente."
        } else {
            amountError = nil
        }
    }

    var isValid: Bool {
        return amount > 0 &&
               amount <= availableBalance &&
               cooldownString == nil &&
               amountError == nil
    }

    // MARK: - Cooldown

    private func startCooldownTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateCooldownStatus()
            }
        updateCooldownStatus()
    }

    private func updateCooldownStatus() {
        guard let lastWin = currentUser?.lastWinTimestamp else {
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

    // MARK: - Actions

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
            do {
                try await requestWithdrawalUseCase.requestWithdrawal(amount: amount)
                HapticManager.notificationSuccess()
                isLoading = false
                completion(true, nil)
            } catch let error as ServiceError {
                isLoading = false
                let message = error.localizedDescription
                errorMessage = message
                completion(false, message)
            } catch {
                isLoading = false
                let message = error.localizedDescription
                errorMessage = message
                completion(false, message)
            }
        }
    }
}
