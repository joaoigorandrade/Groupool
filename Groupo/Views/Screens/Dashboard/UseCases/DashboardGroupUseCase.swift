import Combine
import Foundation

protocol DashboardGroupUseCaseProtocol {
    var currentGroup: AnyPublisher<Group, Never> { get }
}

final class DashboardGroupUseCase: DashboardGroupUseCaseProtocol {
    private let groupService: any GroupServiceProtocol
    
    init(groupService: any GroupServiceProtocol) {
        self.groupService = groupService
    }
    
    var currentGroup: AnyPublisher<Group, Never> {
        groupService.currentGroup
    }
}
