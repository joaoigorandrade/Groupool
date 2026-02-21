import SwiftUI

struct MainTabView: View {
    @Environment(\.services) var services
    @State private var coordinator = MainCoordinator()
    @State private var governanceViewModel: GovernanceViewModel?
    
    var body: some View {
        view
            .adaptiveSheet(isPresented: $coordinator.isPresentingCreateSheet) {
                ActionMenuSheet(destination: $coordinator.activeSheetDestination)
                    .environment(\.services, services)
            }
            .onChange(of: coordinator.isPresentingCreateSheet) { _, isPresented in
                if !isPresented { coordinator.activeSheetDestination = .menu }
            }
    }
    
    @ViewBuilder
    private var view: some View {
        if let gvm = governanceViewModel {
            TabView(selection: tabBinding) {
                dashboardTab(governanceViewModel: gvm)
                createTab
                treasuryTab(governanceViewModel: gvm)
            }
            .environment(coordinator)
        } else {
            ProgressView()
                .onAppear {
                    if governanceViewModel == nil {
                        governanceViewModel = GovernanceViewModel(services: services)
                    }
                }
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
    private func dashboardTab(governanceViewModel: GovernanceViewModel) -> some View {
        DashboardView(
            groupService: services.groupService,
            userService: services.userService,
            challengeService: services.challengeService,
            transactionService: services.transactionService,
            governanceViewModel: governanceViewModel
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
    
    private func treasuryTab(governanceViewModel: GovernanceViewModel) -> some View {
        TreasuryView(
            transactionService: services.transactionService,
            userService: services.userService,
            governanceViewModel: governanceViewModel
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
        .environment(\.services, services)
}
