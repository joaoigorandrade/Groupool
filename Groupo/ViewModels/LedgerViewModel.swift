import Combine
import Foundation

class LedgerViewModel: ObservableObject {
    @Published var sections: [TransactionSection] = []
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
