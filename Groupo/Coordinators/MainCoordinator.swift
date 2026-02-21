import SwiftUI
import Combine

enum MainTab: Hashable {
    case dashboard
    case create
    case treasury
}

@Observable
class MainCoordinator: Coordinator {
    var selectedTab: MainTab = .dashboard
    var isPresentingCreateSheet: Bool = false
    var activeSheetDestination: ActionMenuSheet.Destination = .menu

    func start() { }
    
    func selectTab(_ tab: MainTab) {
        selectedTab = tab
    }
    
    func presentCreateSheet() {
        isPresentingCreateSheet = true
    }
    
    func dismissSheet() {
        isPresentingCreateSheet = false
    }
    
    func presentSheet(_ destination: ActionMenuSheet.Destination) {
        activeSheetDestination = destination
        isPresentingCreateSheet = true
    }
}
