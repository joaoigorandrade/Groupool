//
//  AppSession.swift
//  Groupo
//
//  Created by Antigravity on 2026-02-18.
//

import Foundation

/// Represents the current session state of the user in the app.
/// This enum drives the root view navigation.
public enum AppSession: Equatable {
    /// The session state is not yet determined (e.g., at app launch).
    case unknown
    
    /// The user is not authenticated (needs to log in or sign up).
    case unauthenticated
    
    /// The user is authenticated (phone verified) but has not yet joined a group.
    case authenticated
    
    /// The user is authenticated and is a full member of a group (onboarding complete).
    case onboarded
}
