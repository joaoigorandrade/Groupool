import Combine
import Foundation

protocol TreasuryGroupUseCaseProtocol {
    var currentGroup: AnyPublisher<Group, Never> { get }
}

final class TreasuryGroupUseCase: TreasuryGroupUseCaseProtocol {
    private let groupService: any GroupServiceProtocol
    
    init(groupService: any GroupServiceProtocol) {
        self.groupService = groupService
    }
    
    var currentGroup: AnyPublisher<Group, Never> {
        groupService.currentGroup
    }
}
