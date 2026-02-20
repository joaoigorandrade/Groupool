import Combine
import Foundation

class LedgerViewModel: ObservableObject {
    @Published var sections: [TransactionSection] = []
    @Published var dailySummaries: [DailySummary] = []
    @Published var isLoading: Bool = true
    @Published var errorMessage: String?

    private var hasLoaded: Bool = false
    private var cancellables = Set<AnyCancellable>()
    private let transactionService: any TransactionServiceProtocol

    init(transactionService: any TransactionServiceProtocol) {
        self.transactionService = transactionService
        setupSubscribers()
    }

    @MainActor
    func refresh() async {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }

    private func setupSubscribers() {
        transactionService.transactions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] transactions in
                guard let self else { return }
                if !hasLoaded {
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                        processTransactions(transactions)
                        isLoading = false
                        hasLoaded = true
                    }
                } else {
                    processTransactions(transactions)
                }
            }
            .store(in: &cancellables)
    }

    private func processTransactions(_ transactions: [Transaction]) {
        let sortedTransactions = transactions.sorted { $0.timestamp > $1.timestamp }
        let grouped = Dictionary(grouping: sortedTransactions) { (transaction) -> Date in
            let components = Calendar.current.dateComponents([.year, .month], from: transaction.timestamp)
            return Calendar.current.date(from: components) ?? transaction.timestamp
        }

        let sortedKeys = grouped.keys.sorted(by: >)

        self.sections = sortedKeys.map { date in
            let title = getSectionTitle(for: date)
            let transactions = grouped[date] ?? []
            return TransactionSection(title: title, transactions: transactions)
        }
        
        generateDailySummaries(from: transactions)
    }

    private func generateDailySummaries(from transactions: [Transaction]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var summaries: [DailySummary] = []
        
        // Generate last 60 days summaries for calendar
        for i in 0..<60 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            
            let dayTransactions = transactions.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
            
            var netAmount: Decimal = 0
            for tx in dayTransactions {
                switch tx.type {
                case .win, .refund: netAmount += tx.amount
                case .expense, .withdrawal: netAmount -= tx.amount
                }
            }
            
            summaries.append(DailySummary(date: date, netAmount: netAmount, transactionCount: dayTransactions.count))
        }
        
        self.dailySummaries = summaries.reversed() // Oldest to newest for calendar rendering
    }

    private func getSectionTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date).capitalized
    }
}

struct TransactionSection: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let transactions: [Transaction]
    
    static func == (lhs: TransactionSection, rhs: TransactionSection) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title && lhs.transactions == rhs.transactions
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
