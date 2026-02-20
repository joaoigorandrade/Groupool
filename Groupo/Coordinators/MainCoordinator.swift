import SwiftUI
import Combine

enum MainTab: Hashable {
    case dashboard
    case create
    case treasury
}

class MainCoordinator: Coordinator {
    @Published var selectedTab: MainTab = .dashboard
    @Published var isPresentingCreateSheet: Bool = false
    
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
    
    @Published var activeSheetDestination: ActionMenuSheet.Destination = .menu
    
    func presentSheet(_ destination: ActionMenuSheet.Destination) {
        activeSheetDestination = destination
        isPresentingCreateSheet = true
    }
}
