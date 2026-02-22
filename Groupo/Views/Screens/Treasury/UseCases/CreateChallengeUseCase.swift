import Foundation

protocol CreateChallengeUseCaseProtocol {
    func createChallenge(
        title: String,
        description: String,
        buyIn: Decimal,
        deadline: Date,
        validationMode: Challenge.ValidationMode
    ) async throws
}

final class CreateChallengeUseCase: CreateChallengeUseCaseProtocol {
    private let challengeService: any ChallengeServiceProtocol
    
    init(challengeService: any ChallengeServiceProtocol) {
        self.challengeService = challengeService
    }
    
    func createChallenge(
        title: String,
        description: String,
        buyIn: Decimal,
        deadline: Date,
        validationMode: Challenge.ValidationMode
    ) async throws {
        try await challengeService.addChallenge(
            title: title,
            description: description,
            buyIn: buyIn,
            deadline: deadline,
            validationMode: validationMode
        )
    }
}
