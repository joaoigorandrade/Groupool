import SwiftUI

struct LedgerView: View {
    @EnvironmentObject var coordinator: MainCoordinator
    @StateObject private var viewModel: LedgerViewModel
    
    init(transactionService: any TransactionServiceProtocol) {
        _viewModel = StateObject(wrappedValue: LedgerViewModel(transactionService: transactionService))
    }
    
    var body: some View {
        NavigationStack {
            view
            .navigationTitle("Extrato")
            .background(Color.appPrimaryBackground)
        }
    }
    
    @ViewBuilder
    private var view: some View {
        if viewModel.isLoading {
            List {
                SkeletonView()
            }
            .listStyle(.insetGrouped)
        } else if viewModel.sections.isEmpty {
            ContentUnavailableView {
                Label("No Transactions", systemImage: "list.clipboard")
            } description: {
                Text("Your financial activity will appear here.")
            } actions: {
                Button("Add Transaction") {
                    coordinator.presentCreateSheet()
                }
            }
        } else {
            List {
                ForEach(viewModel.sections) { section in
                    Section(header: Text(section.title)) {
                        ForEach(section.transactions) { transaction in
                            NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                                TransactionRow(transaction: transaction)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .refreshable {
                await viewModel.refresh()
            }
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 16) {
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
                    .font(.headline)
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

#Preview("Populated") {
    let services = AppServiceContainer.preview()
    LedgerView(transactionService: services.transactionService)
        .environmentObject(services)
}

#Preview("Empty") {
    let services = AppServiceContainer.preview()
    LedgerView(transactionService: services.transactionService)
        .environmentObject(services)
}

#Preview("Dark Mode") {
    let services = AppServiceContainer.preview()
    LedgerView(transactionService: services.transactionService)
        .environmentObject(services)
        .preferredColorScheme(.dark)
}
