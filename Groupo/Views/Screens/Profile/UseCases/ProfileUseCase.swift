import Combine
import Foundation

protocol ProfileUseCaseProtocol {
    var currentUser: AnyPublisher<User, Never> { get }
}

final class ProfileUseCase: ProfileUseCaseProtocol {
    private let userService: any UserServiceProtocol
    
    init(userService: any UserServiceProtocol) {
        self.userService = userService
    }
    
    var currentUser: AnyPublisher<User, Never> {
        userService.currentUser
    }
}
