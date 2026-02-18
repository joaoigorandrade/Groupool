//
//  GroupoolApp.swift
//  Groupool
//
//  Created by Joao Igor de Andrade Oliveira on 14/02/26.
//

import SwiftUI

@main
struct GroupoApp: App {
    @StateObject private var services = AppServiceContainer.mock()
    @StateObject private var toastManager = ToastManager()

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()
                    .environmentObject(services)
                    .environmentObject(toastManager)

                ToastView()
                    .environmentObject(toastManager)
            }
        }
    }
}
