import SwiftUI

struct LedgerView: View {
    @EnvironmentObject var dataService: MockDataService
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(dataService.transactions) { transaction in
                    TransactionRow(transaction: transaction)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Ledger")
            .background(Color.primaryBackground)
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon Background
            ZStack {
                Circle()
                    .fill(transactionTypeColor(transaction.type).opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: transactionTypeIcon(transaction.type))
                    .foregroundColor(transactionTypeColor(transaction.type))
                    .font(.system(size: 18, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(.bodyBold)
                    .foregroundColor(.textPrimary)
                
                Text(transaction.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.captionText)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            Text(amountString(for: transaction))
                .font(.bodyBold)
                .foregroundColor(transactionTypeColor(transaction.type))
        }
        .padding(.vertical, 8)
        .listRowBackground(Color.primaryBackground)
        .listRowSeparatorTint(Color.textSecondary.opacity(0.2))
    }
    
    private func transactionTypeIcon(_ type: Transaction.TransactionType) -> String {
        switch type {
        case .expense: return "arrow.down"
        case .withdrawal: return "arrow.up"
        case .win: return "star.fill"
        }
    }
    
    private func transactionTypeColor(_ type: Transaction.TransactionType) -> Color {
        switch type {
        case .expense: return .dangerRed
        case .withdrawal: return .frozenBlue
        case .win: return .availableGreen
        }
    }
    
    private func amountString(for transaction: Transaction) -> String {
        let amount = transaction.amount
        let formatted = amount.formatted(.currency(code: "BRL"))
        
        switch transaction.type {
        case .expense, .withdrawal:
            return "- \(formatted)"
        case .win:
            return "+ \(formatted)"
        }
    }
}

#Preview {
    LedgerView()
        .environmentObject(MockDataService())
}
