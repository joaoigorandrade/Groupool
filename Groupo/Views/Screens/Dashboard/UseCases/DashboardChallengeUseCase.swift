import Combine
import Foundation

protocol DashboardChallengeUseCaseProtocol {
    var challenges: AnyPublisher<[Challenge], Never> { get }
}

final class DashboardChallengeUseCase: DashboardChallengeUseCaseProtocol {
    private let challengeService: any ChallengeServiceProtocol
    
    init(challengeService: any ChallengeServiceProtocol) {
        self.challengeService = challengeService
    }
    
    var challenges: AnyPublisher<[Challenge], Never> {
        challengeService.challenges
    }
}
