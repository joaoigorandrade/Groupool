
import SwiftUI

struct ActivityFeedView: View {
    let transactions: [Transaction]
    let onViewAll: () -> Void
    let onTransactionSelected: (Transaction) -> Void

    @State private var rowsVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView
            contentView
        }
        .dashboardCardStyle()
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.2)) {
                rowsVisible = true
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("RECENT ACTIVITY")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .tracking(1)
            
            Spacer()
            
            Button(action: onViewAll) {
                Text("View All")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.brandTeal)
            }
            .buttonStyle(.plain)
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if transactions.isEmpty {
            ContentUnavailableView(
                "No Recent Activity",
                systemImage: "clock",
                description: Text("Your latest transactions will show up here")
            )
            .frame(height: 100)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(transactions.prefix(3).enumerated()), id: \.element.id) { index, transaction in
                    VStack(spacing: 0) {
                        if index > 0 {
                            Divider()
                                .overlay(Color.white.opacity(0.1))
                                .padding(.leading, 44)
                        }

                        activityRow(for: transaction)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onTransactionSelected(transaction)
                            }
                    }
                    .offset(x: rowsVisible ? 0 : -20)
                    .opacity(rowsVisible ? 1 : 0)
                    .animation(.spring(duration: 0.4, bounce: 0.2).delay(Double(index) * 0.08), value: rowsVisible)
                }
            }
        }
    }
    
    private func activityRow(for transaction: Transaction) -> some View {
        HStack(spacing: 12) {
            transactionIcon(for: transaction)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(transaction.description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text(transaction.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(transaction.formattedAmount())
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(transaction.type.amountColor())
        }
        .padding(.vertical, 10)
    }
    
    private func transactionIcon(for transaction: Transaction) -> some View {
        ZStack {
            Circle()
                .fill(transaction.type.iconColor().opacity(0.1))
                .frame(width: 32, height: 32)
            
            Image(systemName: transaction.type.iconName())
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(transaction.type.iconColor())
        }
    }
}

#Preview {
    let services = AppServiceContainer.preview()
    ZStack {
        Color("PrimaryBackground")
            .ignoresSafeArea()
        
        ActivityFeedView(
            transactions: [Transaction.preview()],
            onViewAll: {},
            onTransactionSelected: { _ in }
        )
        .padding()
    }
}

#Preview {
    let services = AppServiceContainer.preview()
    ZStack {
        Color("PrimaryBackground")
            .ignoresSafeArea()
        
        ActivityFeedView(
            transactions: [Transaction.preview()],
            onViewAll: {},
            onTransactionSelected: { _ in }
        )
            .environment(MainCoordinator())
            .padding()
    }
}
