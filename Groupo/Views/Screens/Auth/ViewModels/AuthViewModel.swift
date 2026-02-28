import Foundation
import Observation

@Observable
final class AuthViewModel {
    // MARK: - Navigation State
    var currentStep: AuthStep = .phoneEntry
    var navigateToDashboard: Bool = false

    // MARK: - Input State
    var phoneNumber: String = ""
    var otpCode: String = "" {
        didSet {
            if otpCode.count > 6 {
                otpCode = String(otpCode.prefix(6))
            }
        }
    }

    // MARK: - UI State
    var isLoading: Bool = false
    var errorMessage: String?
    var timeRemaining: Int = 30
    var canResend: Bool = false

    // MARK: - Constraints
    let countryCode = "+55"
    private var timerTask: Task<Void, Never>?

    // MARK: - Dependencies
    private let authService: any AuthServiceProtocol

    enum AuthStep {
        case phoneEntry
        case otpEntry
    }

    init(authService: any AuthServiceProtocol) {
        self.authService = authService
    }

    deinit {
        timerTask?.cancel()
    }

    // MARK: - Actions

    var isPhoneValid: Bool {
        let digits = phoneNumber.filter { $0.isNumber }
        return digits.count == 11
    }

    func applyPhoneMask(_ input: String) {
        let digits = input.filter { $0.isNumber }
        let limited = String(digits.prefix(11))

        var result = ""
        for (i, char) in limited.enumerated() {
            switch i {
            case 0: result += "(\(char)"
            case 1: result += "\(char)) "
            case 2: result += "\(char)"
            case 6: result += "\(char)-"
            default: result += "\(char)"
            }
        }
        phoneNumber = result
    }

    func sendCode() {
        guard isPhoneValid else { return }

        isLoading = true
        errorMessage = nil

        Task { @MainActor in
            do {
                let rawPhone = phoneNumber.filter { $0.isNumber }
                try await authService.sendOTP(phoneNumber: countryCode + rawPhone)
                self.isLoading = false
                self.currentStep = .otpEntry
                self.startTimer()
            } catch {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func verifyCode(sessionManager: SessionManager) {
        guard otpCode.count == 6 else { return }

        isLoading = true
        errorMessage = nil

        Task { @MainActor in
            do {
                let rawPhone = phoneNumber.filter { $0.isNumber }
                let token = try await authService.verifyOTP(phoneNumber: countryCode + rawPhone, code: otpCode)
                self.isLoading = false
                sessionManager.establishSession(phone: self.countryCode + rawPhone, token: token)
                self.navigateToDashboard = true
            } catch {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func resendCode() {
        guard canResend else { return }

        otpCode = ""
        errorMessage = nil
        timeRemaining = 30
        canResend = false
        sendCode()
    }

    // MARK: - Helpers

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self else { return }
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.canResend = true
                    return
                }
            }
        }
    }

    var maskedPhoneNumber: String {
        let fullPhone = countryCode + phoneNumber
        let digits = fullPhone.filter { $0.isNumber }

        if digits.count >= 13 {
            let areaCode = digits.dropFirst(2).prefix(2)
            let ninthDigit = digits.dropFirst(4).prefix(1)
            let last4 = digits.suffix(4)
            return "+55 \(areaCode) \(ninthDigit)xxxx-\(last4)"
        }

        if digits.count > 4 {
            let last4 = digits.suffix(4)
            let masked = String(repeating: "x", count: digits.count - 4)
            return "\(masked)\(last4)"
        }

        return fullPhone
    }
}
