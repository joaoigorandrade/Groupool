import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var services: AppServiceContainer
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
            DashboardView(
                groupService: services.groupService,
                userService: services.userService,
                challengeService: services.challengeService,
                transactionService: services.transactionService
            )
                .tag(MainTab.dashboard)
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2")
                }
            
            Color.clear
                .tag(MainTab.create)
                .tabItem {
                    Label("New", systemImage: "plus.circle.fill")
                }
            
            TreasuryView(
                 transactionService: services.transactionService,
                 challengeService: services.challengeService,
                 voteService: services.voteService,
                 withdrawalService: services.withdrawalService,
                 userService: services.userService,
                 groupService: services.groupService
             )
                .tag(MainTab.treasury)
                .tabItem {
                    Label("Treasury", systemImage: "building.columns")
                }
        }
        .environmentObject(coordinator)
        .adaptiveSheet(isPresent: $coordinator.isPresentingCreateSheet) {
            ActionMenuSheet(destination: $coordinator.activeSheetDestination)
                .environmentObject(services)
        }
        .onChange(of: coordinator.isPresentingCreateSheet) { _, isPresented in
            if !isPresented { coordinator.activeSheetDestination = .menu }
        }
    }
}

#Preview {
    let services = AppServiceContainer.preview()
    MainTabView()
        .environmentObject(services)
}
