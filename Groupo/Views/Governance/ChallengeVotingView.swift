import SwiftUI

struct ChallengeVotingView: View {
    let challenge: Challenge
    @StateObject private var viewModel = GovernanceViewModel()
    @EnvironmentObject var mockDataService: MockDataService
    @Environment(\.dismiss) var dismiss
    @State private var hasVoted = false
    
    var isParticipant: Bool {
        if let latest = mockDataService.challenges.first(where: { $0.id == challenge.id }) {
            return latest.participants.contains(mockDataService.currentUser.id)
        }
        return false
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(challenge.title)
                    .font(.title)
                    .bold()
                    .padding(.top)
                
                Text(challenge.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Divider()
                
                Text("Proof")
                    .font(.headline)
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.1))
                    .frame(height: 200)
                    .overlay(
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40)
                            .foregroundColor(.secondary)
                    )
                
                if isParticipant {
                    if hasVoted {
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
                                .multilineTextAlignment(.center)
                            
                            Button("Change Vote") {
                                hasVoted = false
                            }
                            .font(.headline)
                            .padding(.top)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .transition(.opacity)
                    } else {
                        VStack(spacing: 12) {
                            Button(action: {
                                vote(.approval)
                            }) {
                                Text("Vote Winner")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            
                            Button(action: {
                                vote(.abstain)
                            }) {
                                Text("Abstain")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .foregroundColor(.primary)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.top)
                    }
                } else {
                    Button(action: {
                        joinChallenge()
                    }) {
                        Text("Join Challenge (Buy-in: \(challenge.buyIn.formatted(.currency(code: "BRL"))))")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.top)
                }
                
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    Text("If the majority does not vote 'Winner', the buy-in will be refunded.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
                
                Spacer()
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.setService(mockDataService)
        }
    }
    
    private func vote(_ type: Vote.VoteType) {
        viewModel.castVote(challenge: challenge, type: type)
        withAnimation {
            hasVoted = true
        }
        HapticManager.impact(style: .medium)
    }
    
    private func joinChallenge() {
        viewModel.joinChallenge(challenge: challenge)
        HapticManager.impact(style: .medium)
    }
}

#Preview {
    NavigationView {
        ChallengeVotingView(challenge: Challenge(
            id: UUID(),
            title: "Mock Challenge",
            description: "Description of the mock challenge.",
            buyIn: 50,
            deadline: Date().addingTimeInterval(3600),
            participants: [],
            status: .voting
        ))
        .environmentObject(MockDataService())
    }
}
