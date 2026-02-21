//
//  GroupoolApp.swift
//  Groupool
//
//  Created by Joao Igor de Andrade Oliveira on 14/02/26.
//

import SwiftUI

@main
struct GroupoApp: App {
    @State private var services = AppServiceContainer.mock()
    @StateObject private var toastManager = ToastManager()
    @StateObject private var sessionManager = SessionManager()

    var body: some Scene {
        WindowGroup {
            ZStack {
                switch sessionManager.session {
                case .unknown:
                    Color.black.ignoresSafeArea()
                    
                case .unauthenticated:
                    PhoneEntryView()
                        .environment(\.services, services)
                        .environmentObject(toastManager)
                        .environmentObject(sessionManager)
                        .transition(.opacity)
                    
                case .authenticated:
                    InviteLandingView(onJoin: {
                        withAnimation {
                            sessionManager.completeOnboarding()
                        }
                    })
                    .environment(\.services, services)
                    .environmentObject(toastManager)
                    .environmentObject(sessionManager)
                    .transition(.opacity)
                    
                case .onboarded:
                    MainTabView()
                        .environment(\.services, services)
                        .environmentObject(toastManager)
                        .environmentObject(sessionManager)
                        .transition(.opacity)
                }

                ToastView()
                    .environmentObject(toastManager)
            }
            .animation(.default, value: sessionManager.session)
        }
    }
}
