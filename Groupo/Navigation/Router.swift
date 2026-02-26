import SwiftUI

@Observable
final class Router {

    // MARK: - Tab State

    var selectedTab: MainTab = .dashboard

    // MARK: - Navigation Paths

    var dashboardPath = NavigationPath()
    var treasuryPath = NavigationPath()

    // MARK: - Sheet State

    var isPresentingSheet = false
    var activeSheetDestination: ActionMenuSheet.Destination = .menu

    // MARK: - Tab Navigation

    func selectTab(_ tab: MainTab) {
        if tab == .create {
            presentSheet()
        } else {
            selectedTab = tab
        }
    }

    // MARK: - Push Navigation

    func push(_ route: DashboardRoute) {
        dashboardPath.append(route)
    }

    func push(_ route: TreasuryRoute) {
        treasuryPath.append(route)
    }

    func navigateBack() {
        switch selectedTab {
        case .dashboard:
            if !dashboardPath.isEmpty { dashboardPath.removeLast() }
        case .treasury:
            if !treasuryPath.isEmpty { treasuryPath.removeLast() }
        case .create:
            break
        }
    }

    func popToRoot() {
        switch selectedTab {
        case .dashboard:
            dashboardPath = NavigationPath()
        case .treasury:
            treasuryPath = NavigationPath()
        case .create:
            break
        }
    }

    // MARK: - Sheet Management

    func presentSheet(_ destination: ActionMenuSheet.Destination = .menu) {
        activeSheetDestination = destination
        isPresentingSheet = true
    }

    func dismissSheet() {
        isPresentingSheet = false
    }
}
