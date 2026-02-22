import Combine
import Foundation

protocol TreasuryVoteUseCaseProtocol {
    var votes: AnyPublisher<[Vote], Never> { get }
    func castVote(targetID: UUID, type: Vote.VoteType) async throws
}

final class TreasuryVoteUseCase: TreasuryVoteUseCaseProtocol {
    private let voteService: any VoteServiceProtocol
    
    init(voteService: any VoteServiceProtocol) {
        self.voteService = voteService
    }
    
    var votes: AnyPublisher<[Vote], Never> {
        voteService.votes
    }
    
    func castVote(targetID: UUID, type: Vote.VoteType) async throws {
        try await voteService.castVote(targetID: targetID, type: type)
    }
}
