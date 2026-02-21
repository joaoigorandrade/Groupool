import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var services: AppServiceContainer
    @State private var coordinator = MainCoordinator()
    
    var body: some View {
        TabView(selection: tabBinding) {
            dashboardTab
            createTab
            treasuryTab
        }
        .environment(coordinator)
        .adaptiveSheet(isPresented: $coordinator.isPresentingCreateSheet) {
            ActionMenuSheet(destination: $coordinator.activeSheetDestination)
                .environmentObject(services)
        }
        .onChange(of: coordinator.isPresentingCreateSheet) { _, isPresented in
            if !isPresented { coordinator.activeSheetDestination = .menu }
        }
    }
}

// MARK: - Tab Selection
private extension MainTabView {
    var tabBinding: Binding<MainTab> {
        Binding(
            get: { coordinator.selectedTab },
            set: { newValue in
                if newValue == .create {
                    coordinator.presentCreateSheet()
                } else {
                    coordinator.selectedTab = newValue
                }
            }
        )
    }
}

// MARK: - Subviews
private extension MainTabView {
    private var dashboardTab: some View {
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
    }
    
    private var createTab: some View {
        Color.clear
            .tag(MainTab.create)
            .tabItem {
                Label("New", systemImage: "plus.circle.fill")
            }
    }
    
    private var treasuryTab: some View {
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
}

#Preview {
    let services = AppServiceContainer.preview()
    MainTabView()
        .environmentObject(services)
}
