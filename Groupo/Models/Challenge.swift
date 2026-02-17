import Foundation

struct Challenge: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let description: String
    let buyIn: Decimal
    let deadline: Date
    var participants: [UUID]
    let status: ChallengeStatus

    enum ChallengeStatus: String, Codable {
        case active
        case voting
        case complete
    }
}
