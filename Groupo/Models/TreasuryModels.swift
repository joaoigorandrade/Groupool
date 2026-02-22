import Foundation

enum GovernanceItem: Identifiable, Hashable {
    case challenge(Challenge)
    case withdrawal(WithdrawalRequest)
    
    var id: UUID {
        switch self {
        case .challenge(let challenge): return challenge.id
        case .withdrawal(let request): return request.id
        }
    }
    
    var deadline: Date {
        switch self {
        case .challenge(let challenge): return challenge.deadline
        case .withdrawal(let request): return request.deadline
        }
    }
    
    var createdDate: Date {
        switch self {
        case .challenge(let challenge): return challenge.createdDate
        case .withdrawal(let request): return request.createdDate
        }
    }
}

struct DailySummary: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let netAmount: Decimal
    let transactionCount: Int
    
    static func == (lhs: DailySummary, rhs: DailySummary) -> Bool {
        lhs.id == rhs.id && lhs.date == rhs.date && lhs.netAmount == rhs.netAmount && lhs.transactionCount == rhs.transactionCount
    }
}

struct TransactionSection: Identifiable {
    var id: String { title }
    let title: String
    let transactions: [Transaction]
}
