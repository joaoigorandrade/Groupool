import Observation
import Foundation
import SwiftUI

@Observable
final class OTPEntryViewModel {
    
    // MARK: - State
    
    var otpCode: String = "" {
        didSet {
            if otpCode.count > 6 {
                otpCode = String(otpCode.prefix(6))
            }
        }
    }
    var timeRemaining: Int = 30
    var canResend: Bool = false
    var errorMessage: String?
    var isLoading: Bool = false
    
    // MARK: - Properties
    
    let phoneNumber: String
    private var timer: Timer?
    
    // MARK: - Init
    
    init(phoneNumber: String) {
        self.phoneNumber = phoneNumber
        startTimer()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// Masked phone number for display (e.g., "+55 11 9xxxx-9999")
    var maskedPhoneNumber: String {
        // Remove all non-numeric characters to handle raw input
        let digits = phoneNumber.filter { $0.isNumber }
        
        // Check if we have enough digits for a Brazil-like mask (+55 11 91234-5678 -> 13 digits)
        if digits.starts(with: "55") && digits.count == 13 { // 55 11 9 1234 5678
            let areaCode = digits.dropFirst(2).prefix(2) // 11
            let ninthDigit = digits.dropFirst(4).prefix(1) // 9
            let last4 = digits.suffix(4)
            
            return "+55 \(areaCode) \(ninthDigit)xxxx-\(last4)"
        }
        
        // Fallback: Mask all but last 4
        if digits.count > 4 {
             let last4 = digits.suffix(4)
             let lengthToMask = digits.count - 4
             let masked = String(repeating: "x", count: lengthToMask)
             return "\(masked)\(last4)"
        }
        
        return phoneNumber
    }
    
    func verifyCode(using sessionManager: SessionManager) {
        guard otpCode.count == 6 else { return }
        
        isLoading = true
        errorMessage = nil
        
        // Mock validation using modern concurrency
        Task {
            // Simulate network delay
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            await MainActor.run {
                self.isLoading = false
                
                if self.otpCode == "123456" {
                    // Success
                    sessionManager.verifyOTP(code: self.otpCode)
                } else {
                    // Failure
                    self.errorMessage = "Invalid code. Please try again."
                }
            }
        }
    }
    
    func resendCode() {
        guard canResend else { return }
        
        // Reset state
        otpCode = ""
        errorMessage = nil
        timeRemaining = 30
        canResend = false
        startTimer()
        
        print("Resending code to \(phoneNumber)")
    }
    
    // MARK: - Private Methods
    
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
}

