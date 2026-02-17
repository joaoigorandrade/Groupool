import SwiftUI

struct LedgerView: View {
    @EnvironmentObject var dataService: MockDataService
    @StateObject private var viewModel = LedgerViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.sections) { section in
                    Section(header: Text(section.title)) {
                        ForEach(section.transactions) { transaction in
                            TransactionRow(transaction: transaction)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Extrato")
            .background(Color.primaryBackground)
            .onAppear {
                viewModel.update(transactions: dataService.transactions)
            }
            .onChange(of: dataService.transactions) { _, newValue in
                viewModel.update(transactions: newValue)
            }
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
                    .fill(transaction.type.iconColor().opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: transaction.type.iconName())
                    .foregroundColor(transaction.type.iconColor())
                    .font(.system(size: 18, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(.headline) // Using standard fonts as per user rule, or custom if defined
                    .foregroundColor(.primary)
                
                Text(transaction.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(transaction.formattedAmount())
                .font(.headline)
                .foregroundColor(transaction.type.amountColor())
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    LedgerView()
        .environmentObject(MockDataService())
}
