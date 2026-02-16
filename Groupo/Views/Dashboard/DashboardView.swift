import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var mockDataService: MockDataService
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("PrimaryBackground")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        poolHeroCard
                        activitySection
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(height: 20)
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .navigationTitle("Dashboard")
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    private var poolHeroCard: some View {
        VStack(spacing: 20) {
            poolValueDisplay
            Divider().background(.white.opacity(0.2))
            memberHealthSummary
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.15), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.15), radius: 25, x: 0, y: 10)
    }
    
    private var poolValueDisplay: some View {
        VStack(spacing: 8) {
            Text("Total Pool")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(1.5)
            
            Text(mockDataService.currentGroup.totalPool.formatted(.currency(code: "BRL")))
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
    }
    
    private var memberHealthSummary: some View {
        let activeCount = mockDataService.currentGroup.members.filter { $0.status == .active }.count
        let totalCount = mockDataService.currentGroup.members.count
        
        return HStack {
            memberStackPreview
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Label("\(activeCount)", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("AvailableGreen"))
                
                if totalCount > activeCount {
                    Label("\(totalCount - activeCount) Paused", systemImage: "pause.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private var memberStackPreview: some View {
        ZStack {
            ForEach(Array(mockDataService.currentGroup.members.prefix(5).enumerated()), id: \.element.id) { index, member in
                memberAvatarCompact(for: member)
                    .offset(x: CGFloat(index) * 20)
                    .zIndex(Double(5 - index))
            }
            
            if mockDataService.currentGroup.members.count > 5 {
                overflowIndicator
                    .offset(x: CGFloat(5 * 20))
                    .zIndex(0)
            }
        }
        .frame(width: CGFloat((min(mockDataService.currentGroup.members.count, 5) + 1) * 20) + 16, height: 36)
    }
    
    private func memberAvatarCompact(for member: User) -> some View {
        Image(systemName: member.avatar)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(member.status == .active ? .primary : .secondary)
            .frame(width: 36, height: 36)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.3), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            .grayscale(member.status != .active ? 1.0 : 0.0)
    }
    
    private var overflowIndicator: some View {
        let remainingCount = mockDataService.currentGroup.members.count - 5
        
        return Text("+\(remainingCount)")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(.secondary)
            .frame(width: 36, height: 36)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.3), lineWidth: 1)
            }
    }
    
    private var activitySection: some View {
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
                    ForEach(Array(mockDataService.transactions.prefix(5))) { transaction in
                        activityRow(for: transaction)
                    }
                }
            }
        }
    }
    
    private func activityRow(for transaction: Transaction) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.secondaryBackground)
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
                
                Text(transaction.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(transaction.formattedAmount())
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(transaction.type.amountColor())
                .monospacedDigit()
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
    DashboardView()
        .environmentObject(MockDataService())
}
