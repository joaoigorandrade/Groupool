import Foundation
import SwiftUI
import Combine

final class AuthViewModel: ObservableObject {
    // MARK: - Navigation State
    @Published var currentStep: AuthStep = .phoneEntry
    @Published var navigateToDashboard: Bool = false

    // MARK: - Input State
    @Published var phoneNumber: String = ""
    @Published var otpCode: String = "" {
        didSet {
            if otpCode.count > 6 {
                otpCode = String(otpCode.prefix(6))
            }
        }
    }

    // MARK: - UI State
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var timeRemaining: Int = 30
    @Published var canResend: Bool = false

    // MARK: - Constraints
    let countryCode = "+55"
    private var timer: Timer?

    // MARK: - Dependencies
    private let authUseCase: AuthUseCaseProtocol
    private let verifyOTPUseCase: VerifyOTPUseCaseProtocol

    enum AuthStep {
        case phoneEntry
        case otpEntry
    }

    init(authUseCase: AuthUseCaseProtocol, verifyOTPUseCase: VerifyOTPUseCaseProtocol) {
        self.authUseCase = authUseCase
        self.verifyOTPUseCase = verifyOTPUseCase
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

        Task {
            do {
                let rawPhone = phoneNumber.filter { $0.isNumber }
                try await authUseCase.sendOTP(phoneNumber: countryCode + rawPhone)
                await MainActor.run {
                    self.isLoading = false
                    self.currentStep = .otpEntry
                    self.startTimer()
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func verifyCode(sessionManager: SessionManager) {
        guard otpCode.count == 6 else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let rawPhone = phoneNumber.filter { $0.isNumber }
                let token = try await verifyOTPUseCase.verifyOTP(phoneNumber: countryCode + rawPhone, code: otpCode)
                await MainActor.run {
                    self.isLoading = false
                    sessionManager.establishSession(phone: self.countryCode + rawPhone, token: token)
                    self.navigateToDashboard = true
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
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
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.canResend = true
                self.timer?.invalidate()
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
