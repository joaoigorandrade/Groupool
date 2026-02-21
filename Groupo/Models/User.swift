import Foundation

struct User: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let avatar: String
    let reputationScore: Int
    let currentEquity: Decimal
    let challengesWon: Int
    let challengesLost: Int
    let lastWinTimestamp: Date?
    let votingHistory: [UUID]
    let consecutiveMissedVotes: Int
    let status: UserStatus

    enum UserStatus: String, Codable {
        case active
        case inactive
        case suspended
    }

    func updating(
        reputationScore: Int? = nil,
        currentEquity: Decimal? = nil,
        challengesWon: Int? = nil,
        challengesLost: Int? = nil,
        lastWinTimestamp: Date? = nil,
        votingHistory: [UUID]? = nil,
        consecutiveMissedVotes: Int? = nil,
        status: UserStatus? = nil
    ) -> User {
        User(
            id: id,
            name: name,
            avatar: avatar,
            reputationScore: reputationScore ?? self.reputationScore,
            currentEquity: currentEquity ?? self.currentEquity,
            challengesWon: challengesWon ?? self.challengesWon,
            challengesLost: challengesLost ?? self.challengesLost,
            lastWinTimestamp: lastWinTimestamp ?? self.lastWinTimestamp,
            votingHistory: votingHistory ?? self.votingHistory,
            consecutiveMissedVotes: consecutiveMissedVotes ?? self.consecutiveMissedVotes,
            status: status ?? self.status
        )
    }
}
