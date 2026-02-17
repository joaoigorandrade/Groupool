import Foundation

struct WithdrawalRequest: Identifiable, Codable, Hashable {
    let id: UUID
    let initiatorID: UUID
    let amount: Decimal
    let status: WithdrawalStatus
    let createdDate: Date
    let deadline: Date

    enum WithdrawalStatus: String, Codable {
        case pending
        case approved
        case rejected
    }
}
