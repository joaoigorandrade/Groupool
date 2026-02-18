import SwiftUI

struct MemberDetailView: View {
    let member: User
    @ObservedObject var viewModel: MemberListViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                
                statsGrid
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color("PrimaryBackground"))
        .navigationTitle("Member Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: member.avatar)
                    .font(.system(size: 60, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 120, height: 120)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Circle())
                
                if member.status == .active {
                    Circle()
                        .fill(Color.green)
                        .stroke(Color("PrimaryBackground"), lineWidth: 4)
                        .frame(width: 32, height: 32)
                }
            }
            
            VStack(spacing: 4) {
                Text(member.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text(member.status.rawValue.capitalized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(statusColor.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
    }
    
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatCard(title: "Reputation", value: "\(member.reputationScore)", icon: "star.fill", color: .yellow)
            
            StatCard(title: "Current Equity", value: member.currentEquity.formatted(.currency(code: "BRL")), icon: "banknote.fill", color: .green)
            
            if viewModel.isFrozen(member: member) {
                StatCard(title: "Frozen Balance", value: viewModel.getFrozenAmount(for: member).formatted(.currency(code: "BRL")), icon: "lock.fill", color: .secondary)
            }
            
            StatCard(title: "Reliability", value: reliabilityPercentage, icon: "checkmark.shield.fill", color: .blue)
            
            StatCard(title: "Challenges Won", value: "\(member.challengesWon)", icon: "trophy.fill", color: .orange)
            
            StatCard(title: "Challenges Lost", value: "\(member.challengesLost)", icon: "xmark.circle.fill", color: .red)
            
            StatCard(title: "Votes Cast", value: "\(member.votingHistory.count)", icon: "hand.raised.fill", color: .purple)
        }
    }
    
    private var reliabilityPercentage: String {
        let total = member.challengesWon + member.challengesLost
        guard total > 0 else { return "N/A" }
        let percentage = Double(member.challengesWon) / Double(total)
        return percentage.formatted(.percent.precision(.fractionLength(0)))
    }
    
    private var statusColor: Color {
        switch member.status {
        case .active: return .green
        case .inactive: return .gray
        case .suspended: return .red
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color("SecondaryBackground"))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        MemberDetailView(member: MockDataService.preview.currentGroup.members.first!, viewModel: MemberListViewModel(mockDataService: MockDataService.preview))
    }
}
