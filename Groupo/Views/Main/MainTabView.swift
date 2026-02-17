import SwiftUI

struct MainTabView: View {
    @StateObject private var coordinator = MainCoordinator()
    
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
            
            GovernanceView()
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
        .sheet(isPresented: $coordinator.isPresentingCreateSheet) {
            ActionMenuSheet()
                .presentationDetents([.large])
        }
    }
}

#Preview {
    DashboardView()
}
