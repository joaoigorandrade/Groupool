import SwiftUI
import Observation

struct ChallengeVotingView: View {
    let challenge: Challenge
    let viewModel: TreasuryViewModel
    
    @Environment(\.services) private var services
    @State private var detailViewModel: ChallengeDetailViewModel?
    @State private var hasUserVoted = false
    
    init(challenge: Challenge, viewModel: TreasuryViewModel) {
        self.challenge = challenge
        self.viewModel = viewModel
    }
    
    private var totalParticipants: Int {
        challenge.participants.count
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let detailViewModel = detailViewModel {
                    ChallengeDetailContent(viewModel: detailViewModel)
                } else {
                    ProgressView()
                }
                
                Divider()
                
                StatusActionsView(challenge: challenge, viewModel: viewModel, hasUserVoted: $hasUserVoted)
                
                if challenge.status != .complete && challenge.status != .failed {
                     FooterSection()
                }
               
                Spacer()
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if detailViewModel == nil {
                detailViewModel = ChallengeDetailViewModel(challenge: challenge, services: services)
            }
            checkUserVoteStatus()
        }
    }
    
    private func checkUserVoteStatus() {
        hasUserVoted = viewModel.hasVoted(on: .challenge(challenge))
    }
}

// MARK: - Subviews

private struct StatusActionsView: View {
    let challenge: Challenge
    let viewModel: TreasuryViewModel
    @Binding var hasUserVoted: Bool
    
    @ViewBuilder
    var body: some View {
        switch challenge.status {
        case .active:
            ActivePhaseActionsView(challenge: challenge, viewModel: viewModel)
        case .voting:
            VotingPhaseActionsView(challenge: challenge, viewModel: viewModel, hasUserVoted: $hasUserVoted)
        case .complete:
            EmptyView()
        case .failed:
            FailedPhaseActionsView(challenge: challenge)
        }
    }
}

private struct ActivePhaseActionsView: View {
    let challenge: Challenge
    let viewModel: TreasuryViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            if !viewModel.isEligibleToVote(on: .challenge(challenge)) {
                JoinChallengeView(challenge: challenge, viewModel: viewModel)
            }
            
            if challenge.validationMode == .votingOnly {
                StartVotingView(challenge: challenge, viewModel: viewModel)
            }
        }
    }
}

private struct JoinChallengeView: View {
    let challenge: Challenge
    let viewModel: TreasuryViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Join this challenge to participate")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            PrimaryButton(
                title: "Join Challenge",
                isLoading: viewModel.isLoading
            ) {
                Task {
                    await viewModel.joinChallenge(challenge: challenge)
                }
            }
            
            Text("Buy-in: \(challenge.buyIn.formatted(.currency(code: "BRL")))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

private struct StartVotingView: View {
    let challenge: Challenge
    let viewModel: TreasuryViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Desafio aceita apenas votação. Inicie a votação quando estiver pronto.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            PrimaryButton(
                title: "Iniciar Votação",
                isLoading: viewModel.isLoading
            ) {
                Task {
                    await viewModel.startVoting(challenge: challenge)
                }
            }
        }
    }
}

private struct VotingPhaseActionsView: View {
    let challenge: Challenge
    let viewModel: TreasuryViewModel
    @Binding var hasUserVoted: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Voting Progress")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack {
                     Text("\(challenge.participants.count) participants")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .padding(.horizontal)
            
            if viewModel.isEligibleToVote(on: .challenge(challenge)) {
                if hasUserVoted {
                    VoteConfirmationView(hasUserVoted: $hasUserVoted, isLoading: viewModel.isLoading)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    VotingButtonsView(challenge: challenge, viewModel: viewModel, hasUserVoted: $hasUserVoted)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            } else {
                Text("Only participants can vote")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }
}

private struct VoteConfirmationView: View {
    @Binding var hasUserVoted: Bool
    let isLoading: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.green)
            
            Text("Vote Cast")
                .font(.title2)
                .bold()
            
            Text("You can change your vote until the deadline.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("Change Vote") {
                withAnimation {
                    hasUserVoted = false
                }
            }
            .font(.headline)
            .padding(.top)
            .disabled(isLoading)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

private struct VotingButtonsView: View {
    let challenge: Challenge
    let viewModel: TreasuryViewModel
    @Binding var hasUserVoted: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Cast Your Vote")
                .font(.headline)
            
            PrimaryButton(
                title: "Vote Winner ✓",
                backgroundColor: .green,
                isLoading: viewModel.isLoading
            ) {
                castVote(.approval)
            }
            
            PrimaryButton(
                title: "Contest ✗",
                backgroundColor: .red,
                isLoading: viewModel.isLoading
            ) {
                castVote(.contest)
            }
            
            Button(action: { castVote(.abstain) }) {
                Text("Abstain")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
            }
            .disabled(viewModel.isLoading)
            
            Button(action: {
                Task {
                    await viewModel.resolveChallenge(challenge: challenge)
                }
            }) {
                Text("Simulate Resolution (Demo)")
                .font(.caption)
                .foregroundColor(.red)
                .padding(.top)
            }
            .disabled(viewModel.isLoading)
        }
    }
    
    private func castVote(_ type: Vote.VoteType) {
        Task {
            await viewModel.castVote(challenge: challenge, type: type)
            HapticManager.notification(type: .success)
            withAnimation(.spring()) {
                hasUserVoted = true
            }
        }
    }
}

private struct FailedPhaseActionsView: View {
    let challenge: Challenge
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.orange)
            
            Text("Challenge Failed")
                .font(.title2)
                .bold()
            
            if let reason = challenge.votingFailureReason {
                Text(reason)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            
            Text("Funds have been refunded/unfrozen.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

private struct FooterSection: View {
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundColor(.secondary)
            Text("If the majority does not vote 'Winner', the buy-in will be refunded.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, 8)
    }
}

#Preview("Active") {
    let services = AppServiceContainer.preview()
    let treasuryVM = TreasuryViewModel(
        transactionService: services.transactionService,
        challengeService: services.challengeService,
        voteService: services.voteService,
        withdrawalService: services.withdrawalService,
        groupService: services.groupService,
        userService: services.userService
    )
    
    NavigationStack {
        ChallengeVotingView(
            challenge: Challenge(
                id: UUID(),
                title: "Mock Challenge",
                description: "Description of the mock challenge.",
                buyIn: 50,
                createdDate: Date(),
                deadline: Date().addingTimeInterval(86400),
                participants: [],
                status: .active
            ),
            viewModel: treasuryVM
        )
        .environment(\.services, services)
    }
}
