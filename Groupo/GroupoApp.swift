//
//  GroupoolApp.swift
//  Groupool
//
//  Created by Joao Igor de Andrade Oliveira on 14/02/26.
//

import SwiftUI

@main
struct GroupoApp: App {
    @StateObject private var router = NavigationRouter()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                ContentView()
                    .environmentObject(router)
            }
        }
    }
}
