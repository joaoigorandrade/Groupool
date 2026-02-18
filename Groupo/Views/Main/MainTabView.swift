import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var mockDataService: MockDataService
    @StateObject private var coordinator = MainCoordinator()
    @State private var sheetDestination: ActionMenuSheet.Destination = .menu
    
    var body: some View {
        let tabBinding = Binding<MainTab>(
            get: { coordinator.selectedTab },
            set: { newValue in
                if newValue == .create {
                    coordinator.presentCreateSheet()
                } else {
                    coordinator.selectedTab = newValue
                }
            }
        )
        
        TabView(selection: tabBinding) {
            DashboardView()
                .tag(MainTab.dashboard)
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2")
                }
            
            LedgerView()
                .tag(MainTab.ledger)
                .tabItem {
                    Label("Ledger", systemImage: "list.bullet.rectangle.portrait")
                }
            
            Color.clear
                .tag(MainTab.create)
                .tabItem {
                    Label("New", systemImage: "plus.circle.fill")
                }
            
            GovernanceView(service: mockDataService)
                .tag(MainTab.governance)
                .tabItem {
                    Label("Governance", systemImage: "checkmark.shield")
                }
            
            ProfileView()
                .tag(MainTab.profile)
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
        .environmentObject(coordinator)
        .adaptiveSheet(isPresent: $coordinator.isPresentingCreateSheet) {
            ViewThatFits {
                ActionMenuSheet(destination: $sheetDestination)
                    .environmentObject(mockDataService)
                ScrollView {
                    ActionMenuSheet(destination: $sheetDestination)
                        .environmentObject(mockDataService)
                }
            }
        }
        .onChange(of: coordinator.isPresentingCreateSheet) { _, isPresented in
            if !isPresented { sheetDestination = .menu }
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(MockDataService.preview)
}
