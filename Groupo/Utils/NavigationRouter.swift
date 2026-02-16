import SwiftUI
import Combine

final class NavigationRouter: ObservableObject {
    @Published var path = NavigationPath()
    
    func navigateTo(_ destination: AnyHashable) {
        path.append(destination)
    }
    
    func navigateBack() {
        path.removeLast()
    }
    
    func popToRoot() {
        path.removeLast(path.count)
    }
}
