import SwiftUI

struct GovernanceView: View {
    @EnvironmentObject var mockDataService: MockDataService
    @EnvironmentObject var coordinator: MainCoordinator
    @StateObject private var viewModel: GovernanceViewModel
    
    init(service: MockDataService) {
        _viewModel = StateObject(wrappedValue: GovernanceViewModel(mockDataService: service))
    }
    
    var body: some View {
        NavigationStack {
            List {
                if viewModel.activeItems.isEmpty {
                    ContentUnavailableView {
                        Label("No Active Votes", systemImage: "checkmark.circle")
                    } description: {
                        Text("There are no active challenges or withdrawal requests at the moment.")
                    } actions: {
                        Button("Create New Proposal") {
                            coordinator.presentCreateSheet()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ForEach(viewModel.activeItems) { item in
                        if case .challenge(let challenge) = item {
                            NavigationLink(destination: ChallengeVotingView(challenge: challenge, service: mockDataService)) {
                                GovernanceListRow(item: item, time: viewModel.timeRemaining(for: item.deadline), showVoteRequired: viewModel.isEligibleToVote(on: item) && !viewModel.hasVoted(on: item))
                            }
                        } else if case .withdrawal(let request) = item {
                             NavigationLink(destination: WithdrawalVotingView(withdrawal: request, service: mockDataService)) {
                                GovernanceListRow(item: item, time: viewModel.timeRemaining(for: item.deadline), showVoteRequired: viewModel.isEligibleToVote(on: item) && !viewModel.hasVoted(on: item))
                            }
                        } else {
                            GovernanceListRow(item: item, time: viewModel.timeRemaining(for: item.deadline), showVoteRequired: viewModel.isEligibleToVote(on: item) && !viewModel.hasVoted(on: item))
                        }
                    }
                }

            }
            .animation(.default, value: viewModel.activeItems)
            .refreshable {
                await viewModel.refresh()
            }
            .navigationTitle("Governance")
            .onAppear {
                // Service is now injected via init
            }
        }
    }
}

struct GovernanceListRow: View {
    let item: GovernanceItem
    let time: String
    var showVoteRequired: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    if showVoteRequired {
                        Circle()
                            .fill(.red)
                            .frame(width: 8, height: 8)
                    }
                }
                
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

#Preview("Populated") {
    GovernanceView(service: MockDataService.preview)
        .environmentObject(MockDataService.preview)
}

#Preview("Empty") {
    GovernanceView(service: MockDataService.empty)
        .environmentObject(MockDataService.empty)
}

#Preview("Dark Mode") {
    GovernanceView(service: MockDataService.preview)
        .environmentObject(MockDataService.preview)
        .preferredColorScheme(.dark)
}
