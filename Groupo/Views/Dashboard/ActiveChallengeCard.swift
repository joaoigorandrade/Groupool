import SwiftUI
import Combine

struct ActiveChallengeCard: View {
    @EnvironmentObject var services: AppServiceContainer
    @EnvironmentObject var coordinator: MainCoordinator
    
    let activeChallenge: Challenge?
    
    var body: some View {
        view
    }
    
    @ViewBuilder
    var view: some View {
        if let challenge = activeChallenge {
            activeChallengeView(for: challenge)
                .padding(20)
                .background(Color("SecondaryBackground"))
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        } else {
            noActiveChallengeView
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
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ACTIVE CHALLENGE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.orange)
                            .tracking(1)
                        
                        Text(challenge.title)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    statusBadge(for: challenge)
                }
                
                HStack(spacing: 24) {
                    metricView(
                        label: "Pot",
                        value: (challenge.buyIn * Decimal(challenge.participants.count)).formatted(.currency(code: "BRL"))
                    )
                    
                    metricView(
                        label: "Buy-in",
                        value: challenge.buyIn.formatted(.currency(code: "BRL"))
                    )
                    
                    metricView(
                        label: "Players",
                        value: "\(challenge.participants.count)"
                    )
                    
                    Spacer()
                }
                
                Divider()
                    .overlay(Color.white.opacity(0.1))
                HStack {
                    Label(timeRemaining(until: challenge.deadline), systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("View Details")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private func metricView(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fontWeight(.medium)
            
            Text(value)
                .font(.callout)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
        }
    }
    
    private func timeRemaining(until deadline: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Ends " + formatter.localizedString(for: deadline, relativeTo: Date())
    }
    
    private var noActiveChallengeView: some View {
        Button(action: {
            coordinator.presentSheet(.challenge)
        }) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.brandTeal)
                
                HStack(spacing: 4) {
                    Text("No Active Challenge.")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Tap to create one.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.brandTeal.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
        ActiveChallengeCard(activeChallenge: nil)
            .environmentObject(services)
            .environmentObject(MainCoordinator())
            .padding()
    }
}
