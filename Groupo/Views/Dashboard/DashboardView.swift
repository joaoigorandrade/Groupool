import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var mockDataService: MockDataService
    @StateObject private var viewModel = DashboardViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("PrimaryBackground")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        poolHeroCard
                        personalStakeCard
                        activeChallengeCard
                        activitySection
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(height: 20)
                    }
                }
                .refreshable {
                    await viewModel.refresh()
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .navigationTitle("Dashboard")
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                viewModel.setup(service: mockDataService)
            }
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
    
    private var personalStakeCard: some View {
        PersonalStakeCard(
            available: mockDataService.currentUserAvailableBalance,
            frozen: mockDataService.currentUserFrozenBalance,
            total: mockDataService.currentUser.currentEquity
        )
    }

    private var activeChallengeCard: some View {
        ActiveChallengeCard()
    }
    
    private var poolValueDisplay: some View {
        VStack(spacing: 8) {
            Text("Total Pool")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(1.5)
            
            Text(viewModel.totalPool.formatted(.currency(code: "BRL")))
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.totalPool)
    }
    
    private var memberHealthSummary: some View {
        let activeCount = viewModel.members.filter { $0.status == .active }.count
        let totalCount = viewModel.members.count
        
        return NavigationLink(destination: MemberListView(mockDataService: mockDataService)) {
            HStack {
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
        .buttonStyle(.plain)
    }
    
    private var memberStackPreview: some View {
        ZStack {
            ForEach(Array(viewModel.members.prefix(5).enumerated()), id: \.element.id) { index, member in
                memberAvatarCompact(for: member)
                    .offset(x: CGFloat(index) * 20)
                    .zIndex(Double(5 - index))
            }
            
            if viewModel.members.count > 5 {
                overflowIndicator
                    .offset(x: CGFloat(5 * 20))
                    .zIndex(0)
            }
        }
        .frame(width: CGFloat((min(viewModel.members.count, 5) + 1) * 20) + 16, height: 36)
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
        let remainingCount = viewModel.members.count - 5
        
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
        ActivityFeedView()
    }
}

#Preview("Populated") {
    DashboardView()
        .environmentObject(MockDataService.preview)
        .environmentObject(MainCoordinator())
}

#Preview("Empty") {
    DashboardView()
        .environmentObject(MockDataService.empty)
        .environmentObject(MainCoordinator())
}

#Preview("Dark Mode") {
    DashboardView()
        .environmentObject(MockDataService.preview)
        .environmentObject(MainCoordinator())
        .preferredColorScheme(.dark)
}
