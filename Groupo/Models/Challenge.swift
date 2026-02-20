import Foundation

struct Challenge: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let description: String
    let buyIn: Decimal
    let createdDate: Date
    let deadline: Date
    var participants: [UUID]
    var status: ChallengeStatus
    var proofImage: String? // URL or base64 string
    var proofSubmissionUserID: UUID?
    var votingFailureReason: String?

    var validationMode: ValidationMode? // Optional for backward compatibility, default to .proof
    
    enum ChallengeStatus: String, Codable {
        case active
        case voting
        case complete
        case failed // If voting fails
    }
    
    enum ValidationMode: String, Codable {
        case proof // Default: requires proof upload
        case votingOnly // No proof, creator starts voting manually
    }
}

extension Challenge {
    static func preview() -> Challenge {
        Challenge(
            id: UUID(),
            title: "Summer Body Challenge",
            description: "Go to the gym 5 times a week for 4 weeks.",
            buyIn: 100.00,
            createdDate: Date().addingTimeInterval(-86400 * 2),
            deadline: Date().addingTimeInterval(86400 * 5),
            participants: [UUID(), UUID()],
            status: .active,
            proofImage: nil,
            proofSubmissionUserID: nil,
            votingFailureReason: nil,
            validationMode: .proof
        )
    }
}
