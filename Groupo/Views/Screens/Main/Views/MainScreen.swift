import SwiftUI

struct MainScreen: View {
    @Environment(\.services) var services
    @State private var router = Router()
    @State private var treasuryViewModel: TreasuryViewModel

    init(services: AppServiceContainer) {
        _treasuryViewModel = State(wrappedValue: TreasuryViewModel(
            transactionService: services.transactionService,
            challengeService: services.challengeService,
            voteService: services.voteService,
            withdrawalService: services.withdrawalService,
            groupService: services.groupService,
            userService: services.userService
        ))
    }

    var body: some View {
        view
            .adaptiveSheet(isPresented: $router.isPresentingSheet) {
                ActionMenuSheet(destination: $router.activeSheetDestination)
                    .environment(\.services, services)
            }
            .onChange(of: router.isPresentingSheet) { _, isPresented in
                if !isPresented { router.activeSheetDestination = .menu }
            }
    }

    @ViewBuilder
    private var view: some View {
        TabView(selection: tabBinding) {
            dashboardTab
            createTab
            treasuryTab
        }
        .environment(router)
    }

    private var tabBinding: Binding<MainTab> {
        Binding(
            get: { router.selectedTab },
            set: { newValue in
                if newValue == .create {
                    router.presentSheet()
                } else {
                    router.selectedTab = newValue
                }
            }
        )
    }

    private var dashboardTab: some View {
        DashboardScreen(
            userService: services.userService,
            groupService: services.groupService,
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
        TreasuryScreen(viewModel: treasuryViewModel)
        .tag(MainTab.treasury)
        .tabItem {
            Label("Treasury", systemImage: "building.columns")
        }
    }
}

#Preview {
    let services = AppServiceContainer.preview()
    return MainScreen(services: services)
        .environment(\.services, services)
}
