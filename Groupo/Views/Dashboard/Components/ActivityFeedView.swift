import SwiftUI
import Combine

struct ActivityFeedView: View {
    @EnvironmentObject private var services: AppServiceContainer
    @EnvironmentObject private var coordinator: MainCoordinator
    
    @State private var transactions: [Transaction] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("RECENT ACTIVITY")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .tracking(1)
                
                Spacer()
                
                Button(action: {
                    coordinator.selectTab(.treasury)
                }) {
                    Text("View All")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.brandTeal)
                }
                .buttonStyle(.plain)
            }
            
            if transactions.isEmpty {
                ContentUnavailableView(
                    "No Recent Activity",
                    systemImage: "clock",
                    description: Text("Your latest transactions will show up here")
                )
                .frame(height: 100)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(transactions.prefix(5).enumerated()), id: \.element.id) { index, transaction in
                        if index > 0 {
                            Divider()
                                .overlay(Color.white.opacity(0.1))
                                .padding(.leading, 44)
                        }
                        
                        activityRow(for: transaction)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                coordinator.selectTab(.treasury)
                            }
                    }
                }
            }
        }
        .padding(20)
        .background(Color("SecondaryBackground"))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .onReceive(services.transactionService.transactions.receive(on: DispatchQueue.main)) {
            transactions = $0
        }
    }
    
    private func activityRow(for transaction: Transaction) -> some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(transaction.type.iconColor().opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: transaction.type.iconName())
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(transaction.type.iconColor())
            }
            
            // Details
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
            
            // Amount
            Text(transaction.formattedAmount())
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(transaction.type.amountColor())
        }
        .padding(.vertical, 10)
    }
}

#Preview {
    let services = AppServiceContainer.preview()
    ZStack {
        Color("PrimaryBackground")
            .ignoresSafeArea()
        
        ActivityFeedView()
            .environmentObject(services)
            .environmentObject(MainCoordinator())
            .padding()
    }
}
