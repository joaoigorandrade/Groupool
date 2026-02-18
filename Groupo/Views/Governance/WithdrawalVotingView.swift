import SwiftUI

struct WithdrawalVotingView: View {
    let withdrawal: WithdrawalRequest
    @StateObject private var viewModel: GovernanceViewModel
    @EnvironmentObject var mockDataService: MockDataService
    
    init(withdrawal: WithdrawalRequest, service: MockDataService) {
        self.withdrawal = withdrawal
        _viewModel = StateObject(wrappedValue: GovernanceViewModel(mockDataService: service))
    }
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
    
    var body: some View {
        VStack(spacing: 24) {
            if hasVoted {
                voteConfirmationView
            } else {
                votingFormView
            }
        }
        .padding()
        .navigationTitle("Withdrawal Request")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Service injected in init
        }
    }
    
    private var votingFormView: some View {
        VStack(alignment: .leading, spacing: 24) {
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
            
            HStack {
                Image(systemName: "timer")
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading) {
                    Text("Auto-Approval in")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.timeRemaining(for: withdrawal.deadline))
                        .font(.headline)
                        .monospacedDigit()
                }
                Spacer()
                Text("Default: Approved")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .foregroundStyle(.green)
                    .cornerRadius(8)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Decision")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        Button {
                            withAnimation {
                                selectedVote = .approve
                                HapticManager.selection()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(selectedVote == .approve ? .green : .secondary.opacity(0.3))
                                
                                VStack(alignment: .leading) {
                                    Text("Approve")
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                    Text("Standard withdrawal")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(height: 56)
                                
                                Spacer()
                                if selectedVote == .approve {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.green)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedVote == .approve ? Color.successGreen : Color.secondary.opacity(0.2), lineWidth: 2)
                                    .background(selectedVote == .approve ? Color.successGreen.opacity(0.1) : Color.clear)
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        
                        
                        Button {
                            withAnimation {
                                selectedVote = .contest
                                HapticManager.selection()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.title2)
                                    .foregroundStyle(selectedVote == .contest ? .orange : .secondary.opacity(0.3))
                                
                                VStack(alignment: .leading) {
                                    Text("Contest")
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                    Text("Flag suspicious activity")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(height: 56)
                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedVote == .contest ? Color.warningOrange : Color.secondary.opacity(0.2), lineWidth: 2)
                                    .background(selectedVote == .contest ? Color.warningOrange.opacity(0.1) : Color.clear)
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if selectedVote == .contest {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reason for contesting")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Menu {
                                ForEach(ContestReason.allCases) { reason in
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
            }
            Spacer()
            
            Button {
                Task {
                    await castVote()
                }
            } label: {
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
    }
    
    private var actionButtonColor: Color {
        switch selectedVote {
        case .approve: return .green
        case .contest: return .orange
        case nil: return .gray
        }
    }
    
    private var voteConfirmationView: some View {
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
            
            Button {
                dismiss()
            } label: {
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

#Preview {
    NavigationStack {
        WithdrawalVotingView(withdrawal: WithdrawalRequest(
            id: UUID(),
            initiatorID: UUID(),
            amount: 500.00,
            status: .pending,
            createdDate: Date(),
            deadline: Date().addingTimeInterval(86400)
        ), service: MockDataService.preview)
        .environmentObject(MockDataService.preview)
    }
}
