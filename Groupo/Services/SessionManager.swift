//
//  SessionManager.swift
//  Groupo
//
//  Created by Antigravity on 2026-02-18.
//

import Combine
import Foundation
import SwiftUI

/// Manages the application's authentication session state and persistence.
/// This class acts as the source of truth for whether a user is logged in or not.
final class SessionManager: ObservableObject {
    
    // MARK: - Published State
    
    /// The current session state of the app.
    @Published var session: AppSession = .unknown
    
    // MARK: - Private Properties
    
    private let userDefaults: UserDefaults
    
    // Keys for persistence
    private let keyPhone = "session_phone"
    private let keyToken = "session_token"
    private let keyOnboarded = "session_onboarded"
    
    // Temporary state during authentication
    private var tempPhone: String?
    
    // MARK: - Init
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        restoreSession()
    }
    
    // MARK: - Public Methods
    
    /// Attempts to restore the session from UserDefaults.
    func restoreSession() {
        let phone = userDefaults.string(forKey: keyPhone)
        let token = userDefaults.string(forKey: keyToken)
        let onboarded = userDefaults.bool(forKey: keyOnboarded)
        
        if let phone = phone, !phone.isEmpty, let token = token, !token.isEmpty {
            // In a real app, we might validate the token with the backend here.
            print("Session restored for \(phone)")
            
            if onboarded {
                self.session = .onboarded
            } else {
                self.session = .authenticated
            }
        } else {
            print("No valid session found")
            self.session = .unauthenticated
        }
    }
    
    /// Initiates the OTP flow by sending a code to the provided phone number.
    /// - Parameter phone: The phone number to send the code to.
    func sendOTP(phone: String) {
        print("Sending OTP to \(phone)...")
        self.tempPhone = phone
    }
    
    /// Establishes a session using a verified identity token.
    /// - Parameter token: The verified identity token (mock).
    func establishSession(token: String) {
        guard let phone = tempPhone else {
            print("Error: No phone number associated with this verification attempt.")
            return
        }
        
        print("Establishing session with token for \(phone)")
        
        // Save persistence data
        userDefaults.set(phone, forKey: keyPhone)
        userDefaults.set(token, forKey: keyToken)
        
        // Clear temporary state
        tempPhone = nil
        
        // Update session state
        self.session = .authenticated
    }
    
    /// Completes the onboarding process and transitions the user to the main app experience.
    func completeOnboarding() {
        print("Completing onboarding...")
        userDefaults.set(true, forKey: keyOnboarded)
        self.session = .onboarded
    }
    
    /// Logs out the current user and clears session data.
    func logout() {
        print("Logging out...")
        userDefaults.removeObject(forKey: keyPhone)
        userDefaults.removeObject(forKey: keyToken)
        userDefaults.removeObject(forKey: keyOnboarded)
        tempPhone = nil
        
        self.session = .unauthenticated
    }
}
