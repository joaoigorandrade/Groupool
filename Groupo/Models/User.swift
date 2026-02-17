import Foundation

struct User: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let avatar: String
    let reputationScore: Int
    let currentEquity: Decimal
    let challengesWon: Int
    let challengesLost: Int
    let status: UserStatus

    enum UserStatus: String, Codable {
        case active
        case inactive
        case suspended
    }
}
