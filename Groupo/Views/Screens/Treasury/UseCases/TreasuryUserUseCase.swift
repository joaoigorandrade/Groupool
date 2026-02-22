import Combine
import Foundation

protocol TreasuryUserUseCaseProtocol {
    var currentUser: AnyPublisher<User, Never> { get }
}

final class TreasuryUserUseCase: TreasuryUserUseCaseProtocol {
    private let userService: any UserServiceProtocol
    
    init(userService: any UserServiceProtocol) {
        self.userService = userService
    }
    
    var currentUser: AnyPublisher<User, Never> {
        userService.currentUser
    }
}
