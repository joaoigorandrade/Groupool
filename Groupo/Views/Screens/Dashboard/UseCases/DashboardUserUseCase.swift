import Combine
import Foundation

protocol DashboardUserUseCaseProtocol {
    var currentUser: AnyPublisher<User, Never> { get }
}

final class DashboardUserUseCase: DashboardUserUseCaseProtocol {
    private let userService: any UserServiceProtocol
    
    init(userService: any UserServiceProtocol) {
        self.userService = userService
    }
    
    var currentUser: AnyPublisher<User, Never> {
        userService.currentUser
    }
}
