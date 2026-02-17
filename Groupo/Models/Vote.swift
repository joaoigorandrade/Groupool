import Foundation

struct Vote: Identifiable, Codable, Hashable {
    let id: UUID
    let voterID: UUID
    let targetID: UUID
    let type: VoteType
    let deadline: Date

    enum VoteType: String, Codable {
        case approval
        case contest
        case abstain
    }
}
