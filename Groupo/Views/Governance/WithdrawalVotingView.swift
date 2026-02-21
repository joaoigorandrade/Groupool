import SwiftUI
import Observation

struct WithdrawalVotingView: View {
    let withdrawal: WithdrawalRequest
    let viewModel: GovernanceViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedVote: VoteOption? = nil
    @State private var contestReason: ContestReason = .pendingDebt
    @State private var hasVoted: Bool = false
    
    enum VoteOption: String, Identifiable, CaseIterable {
        case approve = "No (Approve)"
        case contest = "Yes (Contest)"
        
        var id: String { self.rawValue }
    }
    
    enum ContestReason: String, Identifiable, CaseIterable {
        case pendingDebt = "Pending Debt"
        case fraud = "Suspicious Activity"
        case other = "Other"
        
        var id: String { self.rawValue }
    }
    
    init(withdrawal: WithdrawalRequest, viewModel: GovernanceViewModel) {
        self.withdrawal = withdrawal
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(spacing: 24) {
            if hasVoted {
                WithdrawalVoteConfirmationView(dismissAction: { dismiss() })
            } else {
                WithdrawalVotingFormView(
                    withdrawal: withdrawal,
                    viewModel: viewModel,
                    selectedVote: $selectedVote,
                    contestReason: $contestReason,
                    castVoteAction: {
                        Task {
                            await castVote()
                        }
                    }
                )
            }
        }
        .padding()
        .navigationTitle("Withdrawal Request")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func castVote() async {
        guard let vote = selectedVote else { return }
        
        let type: Vote.VoteType = vote == .approve ? .approval : .contest
        let reasoning = vote == .contest ? contestReason.rawValue : nil
        
        await viewModel.castVote(withdrawal: withdrawal, type: type, reason: reasoning)
        
        withAnimation {
            hasVoted = true
        }
        HapticManager.impact(style: .medium)
    }
}

// MARK: - Subviews

private struct WithdrawalVotingFormView: View {
    let withdrawal: WithdrawalRequest
    let viewModel: GovernanceViewModel
    @Binding var selectedVote: WithdrawalVotingView.VoteOption?
    @Binding var contestReason: WithdrawalVotingView.ContestReason
    let castVoteAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            WithdrawalInitiatorHeader(withdrawal: withdrawal, viewModel: viewModel)
            
            WithdrawalTimerInfo(deadline: withdrawal.deadline, viewModel: viewModel)
            
            Divider()
            
            DecisionSection(selectedVote: $selectedVote, contestReason: $contestReason)
            
            Spacer()
            
            WithdrawalSubmitButton(selectedVote: selectedVote, action: castVoteAction)
        }
    }
}

private struct WithdrawalInitiatorHeader: View {
    let withdrawal: WithdrawalRequest
    let viewModel: GovernanceViewModel
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            if let user = viewModel.getUser(for: withdrawal.initiatorID) {
                Image(systemName: user.avatar)
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(.gray)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                
                VStack(spacing: 4) {
                    Text("\(user.name)")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("wants to withdraw")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Text(withdrawal.amount, format: .currency(code: "BRL"))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.appSecondaryBackground)
        .cornerRadius(16)
    }
}

private struct WithdrawalTimerInfo: View {
    let deadline: Date
    let viewModel: GovernanceViewModel
    
    var body: some View {
        HStack {
            Image(systemName: "timer")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading) {
                Text("Auto-Approval in")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(viewModel.timeRemaining(for: deadline))
                    .font(.headline)
                    .monospacedDigit()
            }
            Spacer()
            StatusBadge(text: "Default: Approved", color: .green)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}

private struct StatusBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .foregroundStyle(color)
            .cornerRadius(8)
    }
}

private struct DecisionSection: View {
    @Binding var selectedVote: WithdrawalVotingView.VoteOption?
    @Binding var contestReason: WithdrawalVotingView.ContestReason
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Your Decision")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    VoteOptionButton(
                        option: .approve,
                        selectedVote: $selectedVote,
                        icon: "checkmark.circle.fill",
                        title: "Approve",
                        subtitle: "Standard withdrawal",
                        activeColor: .green
                    )
                    
                    VoteOptionButton(
                        option: .contest,
                        selectedVote: $selectedVote,
                        icon: "exclamationmark.triangle.fill",
                        title: "Contest",
                        subtitle: "Flag suspicious activity",
                        activeColor: .orange
                    )
                }
                
                if selectedVote == .contest {
                    ContestReasonPicker(contestReason: $contestReason)
                }
            }
        }
    }
}

private struct VoteOptionButton: View {
    let option: WithdrawalVotingView.VoteOption
    @Binding var selectedVote: WithdrawalVotingView.VoteOption?
    let icon: String
    let title: String
    let subtitle: String
    let activeColor: Color
    
    var body: some View {
        Button {
            withAnimation {
                selectedVote = option
                HapticManager.selection()
            }
        } label: {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(selectedVote == option ? activeColor : .secondary.opacity(0.3))
                
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(height: 56)
                
                Spacer()
                if selectedVote == option {
                    Image(systemName: "checkmark")
                        .foregroundStyle(activeColor)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedVote == option ? activeColor : Color.secondary.opacity(0.2), lineWidth: 2)
                    .background(selectedVote == option ? activeColor.opacity(0.1) : Color.clear)
            )
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

private struct ContestReasonPicker: View {
    @Binding var contestReason: WithdrawalVotingView.ContestReason
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reason for contesting")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Menu {
                ForEach(WithdrawalVotingView.ContestReason.allCases) { reason in
                    Button(reason.rawValue) {
                        contestReason = reason
                    }
                }
            } label: {
                HStack {
                    Text(contestReason.rawValue)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(10)
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

private struct WithdrawalSubmitButton: View {
    let selectedVote: WithdrawalVotingView.VoteOption?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(selectedVote == .contest ? "Submit Contest" : "Confirm Approval")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .frame(height: 42)
                .background(actionButtonColor)
                .foregroundStyle(.white)
                .cornerRadius(12)
        }
        .disabled(selectedVote == nil)
        .opacity(selectedVote == nil ? 0.5 : 1.0)
    }
    
    private var actionButtonColor: Color {
        switch selectedVote {
        case .approve: return .green
        case .contest: return .orange
        case nil: return .gray
        }
    }
}

private struct WithdrawalVoteConfirmationView: View {
    let dismissAction: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 40)
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
                .symbolEffect(.bounce)
            
            VStack(spacing: 8) {
                Text("Vote Recorded")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Thank you for helping keep the group safe.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer(minLength: 40)
            
            Button(action: dismissAction) {
                Text("Return to Governance")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .frame(height: 50)
                    .background(Color.secondary.opacity(0.1))
                    .foregroundStyle(.primary)
                    .cornerRadius(12)
            }
        }
    }
}

#Preview {
    let services = AppServiceContainer.preview()
    let governanceVM = GovernanceViewModel(
        challengeService: services.challengeService,
        voteService: services.voteService,
        withdrawalService: services.withdrawalService,
        userService: services.userService,
        groupService: services.groupService
    )
    
    NavigationStack {
        WithdrawalVotingView(
            withdrawal: WithdrawalRequest(
                id: UUID(),
                initiatorID: UUID(),
                amount: 500.00,
                status: .pending,
                createdDate: Date(),
                deadline: Date().addingTimeInterval(86400)
            ),
            viewModel: governanceVM
        )
        .environment(\.services, services)
    }
}
