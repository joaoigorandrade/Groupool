import Foundation

/// Shared logic for computing frozen and available stake amounts
/// from a list of challenges. Used by DashboardViewModel and MemberListViewModel
/// to ensure a single source of truth for stake calculations.
enum ChallengeStakeCalculator {

    /// Returns the challenges in which the given user ID is an active participant
    /// (status is `.active` or `.voting`).
    static func activeChallenges(for userID: UUID, in challenges: [Challenge]) -> [Challenge] {
        challenges.filter {
            ($0.status == .active || $0.status == .voting) &&
            $0.participants.contains(userID)
        }
    }

    /// The total buy-in amount frozen across all active/voting challenges for a user.
    static func frozenAmount(for userID: UUID, in challenges: [Challenge]) -> Decimal {
        activeChallenges(for: userID, in: challenges)
            .reduce(Decimal(0)) { $0 + $1.buyIn }
    }

    /// Whether a user has any stake currently frozen in an active/voting challenge.
    static func hasFrozenStake(for userID: UUID, in challenges: [Challenge]) -> Bool {
        !activeChallenges(for: userID, in: challenges).isEmpty
    }
}
