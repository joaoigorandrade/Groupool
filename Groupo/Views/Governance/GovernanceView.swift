import SwiftUI

struct GovernanceView: View {
    @EnvironmentObject var services: AppServiceContainer
    @EnvironmentObject var coordinator: MainCoordinator
    @StateObject private var viewModel: GovernanceViewModel
    
    init(
        challengeService: any ChallengeServiceProtocol,
        voteService: any VoteServiceProtocol,
        withdrawalService: any WithdrawalServiceProtocol,
        userService: any UserServiceProtocol,
        groupService: any GroupServiceProtocol
    ) {
        _viewModel = StateObject(wrappedValue: GovernanceViewModel(
            challengeService: challengeService,
            voteService: voteService,
            withdrawalService: withdrawalService,
            userService: userService,
            groupService: groupService
        ))
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
                            NavigationLink(destination: ChallengeVotingView(
                                challenge: challenge,
                                challengeService: services.challengeService,
                                voteService: services.voteService,
                                withdrawalService: services.withdrawalService,
                                userService: services.userService,
                                groupService: services.groupService
                            )) {
                                GovernanceListRow(item: item, time: viewModel.timeRemaining(for: item.deadline), progress: viewModel.progress(for: item), showVoteRequired: viewModel.isEligibleToVote(on: item) && !viewModel.hasVoted(on: item))
                            }
                        } else if case .withdrawal(let request) = item {
                             NavigationLink(destination: WithdrawalVotingView(
                                withdrawal: request,
                                challengeService: services.challengeService,
                                voteService: services.voteService,
                                withdrawalService: services.withdrawalService,
                                userService: services.userService,
                                groupService: services.groupService
                             )) {
                                GovernanceListRow(item: item, time: viewModel.timeRemaining(for: item.deadline), progress: viewModel.progress(for: item), showVoteRequired: viewModel.isEligibleToVote(on: item) && !viewModel.hasVoted(on: item))
                            }
                        } else {
                            GovernanceListRow(item: item, time: viewModel.timeRemaining(for: item.deadline), progress: viewModel.progress(for: item), showVoteRequired: viewModel.isEligibleToVote(on: item) && !viewModel.hasVoted(on: item))
                        }
                    }
                }

            }
            .animation(.default, value: viewModel.activeItems)
            .refreshable {
                await viewModel.refresh()
            }
            .navigationTitle("Governance")
        }
    }
}

struct GovernanceListRow: View {
    let item: GovernanceItem
    let time: String
    let progress: Double
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
                
                ProgressView(value: progress)
                    .tint(progressColor)
                    .scaleEffect(x: 1, y: 0.5, anchor: .center)
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
    
    private var progressColor: Color {
        if progress > 0.75 { return .red }
        if progress > 0.5 { return .orange }
        return .green
    }
}

#Preview("Populated") {
    let services = AppServiceContainer.preview()
    GovernanceView(
        challengeService: services.challengeService,
        voteService: services.voteService,
        withdrawalService: services.withdrawalService,
        userService: services.userService,
        groupService: services.groupService
    )
    .environmentObject(services)
}

#Preview("Empty") {
    let services = AppServiceContainer.preview()
    GovernanceView(
        challengeService: services.challengeService,
        voteService: services.voteService,
        withdrawalService: services.withdrawalService,
        userService: services.userService,
        groupService: services.groupService
    )
    .environmentObject(services)
}

#Preview("Dark Mode") {
    let services = AppServiceContainer.preview()
    GovernanceView(
        challengeService: services.challengeService,
        voteService: services.voteService,
        withdrawalService: services.withdrawalService,
        userService: services.userService,
        groupService: services.groupService
    )
    .environmentObject(services)
    .preferredColorScheme(.dark)
}
