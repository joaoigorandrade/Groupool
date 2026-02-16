//
//  GroupoolApp.swift
//  Groupool
//
//  Created by Joao Igor de Andrade Oliveira on 14/02/26.
//

import SwiftUI

@main
struct GroupoApp: App {
    @StateObject private var mockDataService = MockDataService()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(mockDataService)
        }
    }
}
