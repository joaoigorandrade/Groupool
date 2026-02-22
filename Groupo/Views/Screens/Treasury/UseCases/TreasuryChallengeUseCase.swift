import Combine
import Foundation

protocol TreasuryChallengeUseCaseProtocol {
    var challenges: AnyPublisher<[Challenge], Never> { get }
    func joinChallenge(id: UUID) async throws
    func submitProof(challengeID: UUID, imageData: Data?) async throws
    func startVoting(challengeID: UUID) async throws
    func resolveVoting(challengeID: UUID) async throws
}

final class TreasuryChallengeUseCase: TreasuryChallengeUseCaseProtocol {
    private let challengeService: any ChallengeServiceProtocol
    
    init(challengeService: any ChallengeServiceProtocol) {
        self.challengeService = challengeService
    }
    
    var challenges: AnyPublisher<[Challenge], Never> {
        challengeService.challenges
    }
    
    func joinChallenge(id: UUID) async throws {
        try await challengeService.joinChallenge(id: id)
    }
    
    func submitProof(challengeID: UUID, imageData: Data?) async throws {
        try await challengeService.submitProof(challengeID: challengeID, imageData: imageData)
    }
    
    func startVoting(challengeID: UUID) async throws {
        try await challengeService.startVoting(challengeID: challengeID)
    }
    
    func resolveVoting(challengeID: UUID) async throws {
        try await challengeService.resolveVoting(challengeID: challengeID)
    }
}
