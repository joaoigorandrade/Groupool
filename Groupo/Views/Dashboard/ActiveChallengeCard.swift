
import SwiftUI

struct ActiveChallengeCard: View {
    let challenge: Challenge?
    let onCreateChallenge: () -> Void
    let services: AppServiceContainer
    let governanceViewModel: GovernanceViewModel
    
    var body: some View {
        if let challenge = challenge {
            activeChallengeView(for: challenge)
                .dashboardCardStyle()
        } else {
            noActiveChallengeView
                .dashboardCardStyle(backgroundColor: Color.brandTeal.opacity(0.1))
        }
    }
    
    private func activeChallengeView(for challenge: Challenge) -> some View {
        NavigationLink(destination: ChallengeVotingView(
            challenge: challenge,
            viewModel: governanceViewModel
        )) {
            VStack(alignment: .leading, spacing: 16) {
                headerView(for: challenge)
                metricsGrid(for: challenge)
                footerView(for: challenge)
            }
        }
        .buttonStyle(.plain)
    }
    
    private func headerView(for challenge: Challenge) -> some View {
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
    }
    
    private func metricsGrid(for challenge: Challenge) -> some View {
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
    }
    
    private func footerView(for challenge: Challenge) -> some View {
        VStack(spacing: 16) {
            Divider()
                .overlay(Color.white.opacity(0.1))
            
            HStack {
                Label(timeRemaining(until: challenge.deadline), systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("View Details")
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            }
        }
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
        Button(action: onCreateChallenge) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.brandTeal)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("No Active Challenge")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                    
                    Text("Tap to create one and start competing")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary.opacity(0.5))
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
    
    private func statusBadge(for challenge: Challenge) -> some View {
        Text(challenge.status == .voting ? "Voting Open" : "In Progress")
            .font(.caption2.weight(.bold))
            .foregroundStyle(challenge.status == .voting ? .white : .primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                challenge.status == .voting ? Color.blue : Color.green.opacity(0.2)
            )
            .clipShape(Capsule())
    }
}

// MARK: - Styling Extension
extension View {
    func dashboardCardStyle(backgroundColor: Color = Color("SecondaryBackground")) -> some View {
        self
            .padding(20)
            .background(backgroundColor)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

#Preview("Active") {
    let services = AppServiceContainer.preview()
    return ActiveChallengeCard(
        challenge: Challenge.preview(),
        onCreateChallenge: {},
        services: services,
        governanceViewModel: GovernanceViewModel(
            challengeService: services.challengeService,
            voteService: services.voteService,
            withdrawalService: services.withdrawalService,
            userService: services.userService,
            groupService: services.groupService
        )
    )
    .padding()
    .background(Color("PrimaryBackground"))
}

#Preview("Empty") {
    let services = AppServiceContainer.preview()
    return ActiveChallengeCard(
        challenge: nil,
        onCreateChallenge: {},
        services: services,
        governanceViewModel: GovernanceViewModel(
            challengeService: services.challengeService,
            voteService: services.voteService,
            withdrawalService: services.withdrawalService,
            userService: services.userService,
            groupService: services.groupService
        )
    )
    .padding()
    .background(Color("PrimaryBackground"))
}
