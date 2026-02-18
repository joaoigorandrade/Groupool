
import SwiftUI
import Combine

struct ActiveChallengeCard: View {
    @EnvironmentObject var services: AppServiceContainer
    @EnvironmentObject var coordinator: MainCoordinator
    
    @State private var challenges: [Challenge] = []
    
    private var activeChallenge: Challenge? {
        challenges.first { $0.status == .active || $0.status == .voting }
    }
    
    var body: some View {
        SwiftUI.Group {
            if let challenge = activeChallenge {
                activeChallengeView(for: challenge)
            } else {
                noActiveChallengeView
            }
        }
        .padding(20)
        .background(Color("SecondaryBackground")) // Fallback if not defined, or use material
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .onReceive(services.challengeService.challenges.receive(on: DispatchQueue.main)) {
            challenges = $0
        }
    }
    
    private func activeChallengeView(for challenge: Challenge) -> some View {
        NavigationLink(destination: ChallengeVotingView(
            challenge: challenge,
            challengeService: services.challengeService,
            voteService: services.voteService,
            withdrawalService: services.withdrawalService,
            userService: services.userService,
            groupService: services.groupService
        )) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Active Challenge", systemImage: "flag.fill")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                        .textCase(.uppercase)
                        .tracking(1)
                    
                    Spacer()
                    
                    Text("ENDS IN 2D") // Placeholder for now or calculated
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text("Buy-in: \(challenge.buyIn.formatted(.currency(code: "BRL")))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    // Quick status indicator
                     statusBadge(for: challenge)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private var noActiveChallengeView: some View {
        Button(action: {
            coordinator.presentSheet(.challenge)
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.brandTeal.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "plus")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.brandTeal)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("No Active Challenge")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text("Tap to create one")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary.opacity(0.5))
            }
        }
        .buttonStyle(.plain)
    }
    
    private func statusBadge(for challenge: Challenge) -> some View {
        Text(challenge.status == .voting ? "Voting Open" : "In Progress")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(challenge.status == .voting ? .white : .primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                challenge.status == .voting ? Color.blue : Color.green.opacity(0.2)
            )
            .clipShape(Capsule())
    }
}

#Preview {
    let services = AppServiceContainer.preview()
    ZStack {
        Color.black.ignoresSafeArea()
        ActiveChallengeCard()
            .environmentObject(services)
            .environmentObject(MainCoordinator())
            .padding()
    }
}
