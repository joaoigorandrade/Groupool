import Foundation
import Combine

class LedgerViewModel: ObservableObject {
    @Published var sections: [TransactionSection] = []
    @Published var isLoading: Bool = true
    
    private var hasLoaded: Bool = false
    
    @MainActor
    func update(transactions: [Transaction]) {
        if !hasLoaded {
            // Simulate initial load
            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                processTransactions(transactions)
                isLoading = false
                hasLoaded = true
            }
        } else {
            // Real-time updates (no delay)
            processTransactions(transactions)
        }
    }
    
    @MainActor
    func refresh(transactions: [Transaction]) async {
        // We don't set isLoading to true here because refreshable shows its own spinner
        // But we can simulate the delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        processTransactions(transactions)
    }
    
    private func processTransactions(_ transactions: [Transaction]) {
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
    
    // Kept private helper logic outside update

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
