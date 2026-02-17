import Foundation
import Combine

class LedgerViewModel: ObservableObject {
    @Published var sections: [TransactionSection] = []
    
    func update(transactions: [Transaction]) {
        let sortedTransactions = transactions.sorted { $0.timestamp > $1.timestamp }
        let grouped = Dictionary(grouping: sortedTransactions) { (transaction) -> Date in
            return Calendar.current.startOfDay(for: transaction.timestamp)
        }
        
        let sortedKeys = grouped.keys.sorted(by: >)
        
        self.sections = sortedKeys.map { date in
            let title = getSectionTitle(for: date)
            let transactions = grouped[date] ?? []
            return TransactionSection(title: title, transactions: transactions)
        }
    }
    
    private func getSectionTitle(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Hoje"
        } else if calendar.isDateInYesterday(date) {
            return "Ontem"
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "pt_BR")
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: date).capitalized
        }
    }
}

struct TransactionSection: Identifiable {
    let id = UUID()
    let title: String
    let transactions: [Transaction]
}
