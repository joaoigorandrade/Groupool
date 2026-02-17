import SwiftUI

struct Transaction: Identifiable, Codable, Hashable {
    let id: UUID
    let description: String
    let amount: Decimal
    let type: TransactionType
    let timestamp: Date
    let relatedChallengeID: UUID?
    let splitDetails: [String: Decimal]?


    enum TransactionType: String, Codable {
        case expense
        case withdrawal
        case win
        
        func iconName() -> String {
            switch self {
            case .expense: return "arrow.down"
            case .withdrawal: return "arrow.up"
            case .win: return "star.fill"
            }
        }
        
        func iconColor() -> Color {
            switch self {
            case .expense: return Color("DangerRed")
            case .withdrawal: return Color("FrozenBlue")
            case .win: return Color("AvailableGreen")
            }
        }
        
        func amountColor() -> Color {
            switch self {
            case .expense, .withdrawal: return Color("DangerRed")
            case .win: return Color("AvailableGreen")
            }
        }
    }
    
    func formattedAmount() -> String {
        let formatted = self.amount.formatted(.currency(code: "BRL"))
        switch self.type {
        case .expense, .withdrawal: return "-\(formatted)"
        case .win: return "+\(formatted)"
        }
    }
}
