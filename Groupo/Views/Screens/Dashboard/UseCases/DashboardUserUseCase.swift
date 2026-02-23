import Combine
import Foundation

protocol DashboardUserUseCaseProtocol {
    var currentUser: AnyPublisher<User, Never> { get }
    func refresh() async
}

final class DashboardUserUseCase: DashboardUserUseCaseProtocol {
    private let userService: any UserServiceProtocol

    init(userService: any UserServiceProtocol) {
        self.userService = userService
    }

    var currentUser: AnyPublisher<User, Never> {
        userService.currentUser
    }

    func refresh() async {
        await userService.refresh()
    }
}
