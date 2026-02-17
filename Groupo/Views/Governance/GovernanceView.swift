import SwiftUI

struct GovernanceView: View {
    @EnvironmentObject var mockDataService: MockDataService
    @StateObject private var viewModel = GovernanceViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                if viewModel.activeItems.isEmpty {
                    ContentUnavailableView(
                        "No Active Votes",
                        systemImage: "checkmark.circle",
                        description: Text("There are no active challenges or withdrawal requests at the moment.")
                    )
                } else {
                    ForEach(viewModel.activeItems) { item in
                        if case .challenge(let challenge) = item {
                            NavigationLink(destination: ChallengeVotingView(challenge: challenge)) {
                                GovernanceListRow(item: item, time: viewModel.timeRemaining(for: item.deadline))
                            }
                        } else if case .withdrawal(let request) = item {
                             NavigationLink(destination: WithdrawalVotingView(withdrawal: request)) {
                                GovernanceListRow(item: item, time: viewModel.timeRemaining(for: item.deadline))
                            }
                        } else {
                            GovernanceListRow(item: item, time: viewModel.timeRemaining(for: item.deadline))
                        }
                    }
                }
            }
            .navigationTitle("Governance")
            .onAppear {
                viewModel.setService(mockDataService)
            }
        }
    }
}

struct GovernanceListRow: View {
    let item: GovernanceItem
    let time: String
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            
            Spacer()
            
            if case .challenge(let challenge) = item {
                Text(challenge.buyIn, format: .currency(code: "BRL"))
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(6)
                    .background(Color.primary.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var iconName: String {
        switch item {
        case .challenge: return "flag.fill"
        case .withdrawal: return "arrow.up.circle.fill"
        }
    }
    
    private var iconColor: Color {
        switch item {
        case .challenge: return .orange
        case .withdrawal: return .blue
        }
    }
    
    private var title: String {
        switch item {
        case .challenge(let challenge): return challenge.title
        case .withdrawal: return "Withdrawal Request"
        }
    }
}

#Preview {
    GovernanceView()
        .environmentObject(MockDataService())
}
