import SwiftUI
import Combine

enum MainTab: Hashable {
    case dashboard
    case ledger
    case create // The middle "button"
    case governance
    case profile
}

class MainCoordinator: Coordinator {
    @Published var selectedTab: MainTab = .dashboard
    @Published var isPresentingCreateSheet: Bool = false
    
    func start() {
        // Initial setup if needed
    }
    
    func selectTab(_ tab: MainTab) {
        selectedTab = tab
    }
    
    func presentCreateSheet() {
        isPresentingCreateSheet = true
    }
    
    func dismissSheet() {
        isPresentingCreateSheet = false
    }
}
