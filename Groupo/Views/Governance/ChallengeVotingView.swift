import SwiftUI

struct ChallengeVotingView: View {
    let challenge: Challenge
    @StateObject private var viewModel: GovernanceViewModel
    
    init(
        challenge: Challenge,
        challengeService: any ChallengeServiceProtocol,
        voteService: any VoteServiceProtocol,
        withdrawalService: any WithdrawalServiceProtocol,
        userService: any UserServiceProtocol,
        groupService: any GroupServiceProtocol
    ) {
        self.challenge = challenge
        _viewModel = StateObject(wrappedValue: GovernanceViewModel(
            challengeService: challengeService,
            voteService: voteService,
            withdrawalService: withdrawalService,
            userService: userService,
            groupService: groupService
        ))
    }
    
    @State private var hasUserVoted = false
    
    // Derived state for voting progress
    private var totalParticipants: Int {
        challenge.participants.count
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Shared Detail View
                ChallengeDetailContent(challenge: challenge)
                
                Divider()
                
                // Interactive functionality based on status
                statusActions
                
                if challenge.status != .complete && challenge.status != .failed {
                     footerSection
                }
               
                Spacer()
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkUserVoteStatus()
        }
    }
}

// MARK: - Subviews
private extension ChallengeVotingView {
    
    @ViewBuilder
    var statusActions: some View {
        switch challenge.status {
        case .active:
            activePhaseActions
        case .voting:
            votingPhaseActions
        case .complete:
            EmptyView()
        case .failed:
            failedPhaseActions
        }
    }
    
    var footerSection: some View {
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

// MARK: - Active Phase Actions
private extension ChallengeVotingView {
    @ViewBuilder
    var activePhaseActions: some View {
        VStack(spacing: 16) {
            if !viewModel.isEligibleToVote(on: .challenge(challenge)) {
                joinChallengeView
            }
            
            if challenge.validationMode == .votingOnly {
                startVotingView
            }
        }
    }
    
    var joinChallengeView: some View {
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
    
    var startVotingView: some View {
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

// MARK: - Voting Phase Actions
private extension ChallengeVotingView {
    @ViewBuilder
    var votingPhaseActions: some View {
        VStack(spacing: 24) {
            // Voting Progress
            VStack(spacing: 8) {
                Text("Voting Progress")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack {
                     Text("\(totalParticipants) participants")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .padding(.horizontal)
            
            if viewModel.isEligibleToVote(on: .challenge(challenge)) {
                if hasUserVoted {
                    voteConfirmationView
                        .transition(.scale.combined(with: .opacity))
                } else {
                    votingControlsView
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
    
    @ViewBuilder
    var votingControlsView: some View {
        votingButtons
    }
    
    var voteConfirmationView: some View {
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
            .disabled(viewModel.isLoading)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    var votingButtons: some View {
        VStack(spacing: 12) {
            Text("Cast Your Vote")
                .font(.headline)
            
            PrimaryButton(
                title: "Vote Winner ✓",
                backgroundColor: .green,
                isLoading: viewModel.isLoading
            ) {
                vote(.approval)
            }
            
            PrimaryButton(
                title: "Contest ✗",
                backgroundColor: .red,
                isLoading: viewModel.isLoading
            ) {
                vote(.contest)
            }
            
            Button(action: { vote(.abstain) }) {
                Text("Abstain")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
            }
            .disabled(viewModel.isLoading)
            
            Button(action: simulateResolution) {
                Text("Simulate Resolution (Demo)")
                .font(.caption)
                .foregroundColor(.red)
                .padding(.top)
            }
            .disabled(viewModel.isLoading)
        }
    }
}

// MARK: - Failed Phase Actions
private extension ChallengeVotingView {
    @ViewBuilder
    var failedPhaseActions: some View {
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

// MARK: - Helper Methods
private extension ChallengeVotingView {
    func vote(_ type: Vote.VoteType) {
        Task {
            await viewModel.castVote(challenge: challenge, type: type)
            HapticManager.notification(type: .success)
            withAnimation(.spring()) {
                hasUserVoted = true
            }
        }
    }
    
    func checkUserVoteStatus() {
        hasUserVoted = viewModel.hasVoted(on: .challenge(challenge))
    }
    
    func simulateResolution() {
        Task {
            await viewModel.resolveChallenge(challenge: challenge)
        }
    }
}

#Preview("Active") {
    let services = AppServiceContainer.preview()
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
            challengeService: services.challengeService,
            voteService: services.voteService,
            withdrawalService: services.withdrawalService,
            userService: services.userService,
            groupService: services.groupService
        )
        .environmentObject(services)
    }
}

#Preview("Voting") {
    let services = AppServiceContainer.preview()
    NavigationStack {
        ChallengeVotingView(
            challenge: Challenge(
                id: UUID(),
                title: "Voting Challenge",
                description: "Voting in progress.",
                buyIn: 50,
                createdDate: Date(),
                deadline: Date().addingTimeInterval(86400),
                participants: [],
                status: .voting
            ),
            challengeService: services.challengeService,
            voteService: services.voteService,
            withdrawalService: services.withdrawalService,
            userService: services.userService,
            groupService: services.groupService
        )
        .environmentObject(services)
    }
}

#Preview("Completed") {
    let services = AppServiceContainer.preview()
    NavigationStack {
        ChallengeVotingView(
            challenge: Challenge(
                id: UUID(),
                title: "Completed Challenge",
                description: "Challenge finished.",
                buyIn: 50,
                createdDate: Date().addingTimeInterval(-86400),
                deadline: Date().addingTimeInterval(-3600),
                participants: [],
                status: .complete
            ),
            challengeService: services.challengeService,
            voteService: services.voteService,
            withdrawalService: services.withdrawalService,
            userService: services.userService,
            groupService: services.groupService
        )
        .environmentObject(services)
    }
}
