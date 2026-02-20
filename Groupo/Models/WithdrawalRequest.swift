import Foundation

struct WithdrawalRequest: Identifiable, Codable, Hashable {
    let id: UUID
    let initiatorID: UUID
    let amount: Decimal
    var status: WithdrawalStatus
    let createdDate: Date
    let deadline: Date

    enum WithdrawalStatus: String, Codable {
        case pending
        case approved
        case rejected
    }
}

extension WithdrawalRequest {
    static func preview() -> WithdrawalRequest {
        WithdrawalRequest(
            id: UUID(),
            initiatorID: UUID(),
            amount: 250.00,
            status: .pending,
            createdDate: Date().addingTimeInterval(-3600),
            deadline: Date().addingTimeInterval(86400)
        )
    }
}
