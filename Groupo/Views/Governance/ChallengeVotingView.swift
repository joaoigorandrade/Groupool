import SwiftUI

struct ChallengeVotingView: View {
    let challenge: Challenge
    @StateObject private var viewModel: GovernanceViewModel
    @EnvironmentObject var mockDataService: MockDataService
    
    init(challenge: Challenge, service: MockDataService) {
        self.challenge = challenge
        _viewModel = StateObject(wrappedValue: GovernanceViewModel(mockDataService: service))
    }
    
    @State private var hasUserVoted = false
    
    private var currentChallenge: Challenge {
        mockDataService.challenges.first(where: { $0.id == challenge.id }) ?? challenge
    }
    
    // Derived state for voting progress
    private var totalParticipants: Int {
        currentChallenge.participants.count
    }
    
    private var votesCast: Int {
        mockDataService.votes.filter { $0.targetID == currentChallenge.id }.count
    }
    
    private var myVote: Vote? {
        mockDataService.votes.first(where: { $0.targetID == currentChallenge.id && $0.voterID == mockDataService.currentUser.id })
    }
    
    private var isParticipant: Bool {
        currentChallenge.participants.contains(mockDataService.currentUser.id)
    }
    
    private var isCreator: Bool {
        currentChallenge.participants.first == mockDataService.currentUser.id
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Shared Detail View
                ChallengeDetailView(challenge: currentChallenge)
                
                Divider()
                
                // Interactive functionality based on status
                statusActions
                
                if currentChallenge.status != .complete && currentChallenge.status != .failed {
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
        switch currentChallenge.status {
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
            if !isParticipant {
                joinChallengeView
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
                    await viewModel.joinChallenge(challenge: currentChallenge)
                }
            }
            
            Text("Buy-in: \(currentChallenge.buyIn.formatted(.currency(code: "BRL")))")
                .font(.caption)
                .foregroundColor(.secondary)
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
                     Text("\(votesCast) of \(totalParticipants) voted")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    if totalParticipants > 0 {
                          Text("\(Int((Double(votesCast) / Double(totalParticipants)) * 100))%")
                            .font(.caption)
                            .bold()
                    }
                }
                
                ProgressView(value: Double(votesCast), total: Double(totalParticipants))
                    .tint(.blue)
            }
            .padding(.horizontal)
            
            if isParticipant {
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
                .foregroundColor(myVote?.type == .approval ? .green : (myVote?.type == .contest ? .red : .gray))
            
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
        .overlay(alignment: .topTrailing) {
             if let voteType = myVote?.type {
                 Text(voteType == .approval ? "Voted Winner" : (voteType == .contest ? "Contested" : "Abstained"))
                     .font(.caption)
                     .fontWeight(.bold)
                     .padding(6)
                     .background(Color.secondary.opacity(0.1))
                     .cornerRadius(6)
             }
        }
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
            
            if isCreator {
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
            
            if let reason = currentChallenge.votingFailureReason {
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
    func joinChallenge() {
        Task {
            await viewModel.joinChallenge(challenge: currentChallenge)
        }
    }
    
    func vote(_ type: Vote.VoteType) {
        Task {
            await viewModel.castVote(challenge: currentChallenge, type: type)
            HapticManager.notification(type: .success)
            withAnimation(.spring()) {
                hasUserVoted = true
            }
        }
    }
    
    private func checkUserVoteStatus() {
        if mockDataService.votes.first(where: { $0.targetID == currentChallenge.id && $0.voterID == mockDataService.currentUser.id }) != nil {
            hasUserVoted = true
        } else {
            hasUserVoted = false
        }
    }
    
    func simulateResolution() {
        Task {
            await viewModel.resolveChallenge(challenge: currentChallenge)
        }
    }
}

#Preview("Active") {
    NavigationStack {
        ChallengeVotingView(challenge: Challenge(
            id: UUID(),
            title: "Mock Challenge",
            description: "Description of the mock challenge.",
            buyIn: 50,
            deadline: Date().addingTimeInterval(3600),
            participants: [],
            status: .active
        ), service: MockDataService.preview)
        .environmentObject(MockDataService.preview)
    }
}

#Preview("Voting") {
    NavigationStack {
        ChallengeVotingView(challenge: Challenge(
            id: UUID(),
            title: "Voting Challenge",
            description: "Voting in progress.",
            buyIn: 50,
            deadline: Date().addingTimeInterval(3600),
            participants: [],
            status: .voting
        ), service: MockDataService.preview)
        .environmentObject(MockDataService.preview)
    }
}

#Preview("Completed") {
    NavigationStack {
        ChallengeVotingView(challenge: Challenge(
            id: UUID(),
            title: "Completed Challenge",
            description: "Challenge finished.",
            buyIn: 50,
            deadline: Date().addingTimeInterval(-3600),
            participants: [],
            status: .complete
        ), service: MockDataService.preview)
        .environmentObject(MockDataService.preview)
    }
}
