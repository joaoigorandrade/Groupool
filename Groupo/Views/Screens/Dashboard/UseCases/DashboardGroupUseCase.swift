import Combine
import Foundation

protocol DashboardGroupUseCaseProtocol {
    var currentGroup: AnyPublisher<Group, Never> { get }
    func refresh() async
}

final class DashboardGroupUseCase: DashboardGroupUseCaseProtocol {
    private let groupService: any GroupServiceProtocol

    init(groupService: any GroupServiceProtocol) {
        self.groupService = groupService
    }

    var currentGroup: AnyPublisher<Group, Never> {
        groupService.currentGroup
    }

    func refresh() async {
        await groupService.refresh()
    }
}
