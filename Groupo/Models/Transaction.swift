import Foundation

struct Transaction: Identifiable, Codable, Hashable {
    let id: UUID
    let description: String
    let amount: Decimal
    let type: TransactionType
    let timestamp: Date

    enum TransactionType: String, Codable {
        case expense
        case withdrawal
        case win
    }
}
