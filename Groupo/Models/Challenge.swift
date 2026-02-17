import Foundation

struct Challenge: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let description: String
    let buyIn: Decimal
    let deadline: Date
    var participants: [UUID]
    var status: ChallengeStatus
    var proofImage: String? // URL or base64 string
    var proofSubmissionUserID: UUID?
    var votingFailureReason: String?

    enum ChallengeStatus: String, Codable {
        case active
        case voting
        case complete
        case failed // If voting fails
    }
}
