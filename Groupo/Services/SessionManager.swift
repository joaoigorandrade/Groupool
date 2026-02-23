//
//  SessionManager.swift
//  Groupo
//
//  Created by Antigravity on 2026-02-18.
//

import Combine
import Foundation
import SwiftUI

final class SessionManager: ObservableObject {
    
    // MARK: - Published State
    
    @Published var session: AppSession = .unknown
    
    // MARK: - Private Properties
    
    private let userDefaults: UserDefaults
    private let keyPhone = "session_phone"
    private let keyToken = "session_token"
    private let keyOnboarded = "session_onboarded"
    
    // MARK: - Init
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        restoreSession()
    }
    
    // MARK: - Public Methods
    
    func restoreSession() {
        let phone = userDefaults.string(forKey: keyPhone)
        let token = userDefaults.string(forKey: keyToken)
        let onboarded = userDefaults.bool(forKey: keyOnboarded)
        
        if let phone = phone, !phone.isEmpty, let token = token, !token.isEmpty {
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
    
    func establishSession(phone: String, token: String) {
        print("Establishing session with token for \(phone)")

        userDefaults.set(phone, forKey: keyPhone)
        userDefaults.set(token, forKey: keyToken)

        self.session = .authenticated
    }
    
    func completeOnboarding() {
        userDefaults.set(true, forKey: keyOnboarded)
        self.session = .onboarded
    }
    
    func logout() {
        userDefaults.removeObject(forKey: keyPhone)
        userDefaults.removeObject(forKey: keyToken)
        userDefaults.removeObject(forKey: keyOnboarded)

        self.session = .unauthenticated
    }
}
