//
//  PhoneEntryViewModel.swift
//  Groupo
//
//  Created by Antigravity on 2026-02-18.
//

import SwiftUI
import Combine

class PhoneEntryViewModel: ObservableObject {
    @Published var phoneNumber: String = ""
    @Published var navigateToOTP: Bool = false
    
    let countryCode = "+55"
    
    var isValid: Bool {
        // Remove non-digit characters to count actual digits
        let digits = phoneNumber.filter { $0.isNumber }
        return digits.count >= 10
    }
    
    func sendCode(sessionManager: SessionManager) {
        guard isValid else { return }
        
        // Mock: Print the code to console
        print("Sending code to \(countryCode) \(phoneNumber)...")
        print("Generated Code: 123456")
        
        // Start OTP flow
        sessionManager.sendOTP(phone: phoneNumber)
        
        // Trigger navigation
        navigateToOTP = true
    }
}
