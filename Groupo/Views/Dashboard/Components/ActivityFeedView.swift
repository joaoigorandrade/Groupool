import SwiftUI

struct ActivityFeedView: View {
    @EnvironmentObject private var mockDataService: MockDataService
    @EnvironmentObject private var coordinator: MainCoordinator
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            
            if mockDataService.transactions.isEmpty {
                ContentUnavailableView(
                    "No Activity Yet",
                    systemImage: "tray",
                    description: Text("Transactions will appear here")
                )
                .frame(height: 150)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(mockDataService.transactions.prefix(3))) { transaction in
                        activityRow(for: transaction)
                            .onTapGesture {
                                coordinator.selectTab(.ledger)
                            }
                    }
                }
            }
        }
    }
    
    private func activityRow(for transaction: Transaction) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color("SecondaryBackground"))
                    .frame(width: 44, height: 44)
                    .shadow(radius: 2)
                
                Image(systemName: transaction.type.iconName())
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(transaction.type.iconColor())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.primary)
                
                Text(transaction.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        }
    }
}

#Preview {
    ZStack {
        Color("PrimaryBackground")
            .ignoresSafeArea()
        
        ActivityFeedView()
            .environmentObject(MockDataService())
            .environmentObject(MainCoordinator())
            .padding()
    }
}
