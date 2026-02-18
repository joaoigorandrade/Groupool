// ServiceError.swift

import Foundation

enum ServiceError: LocalizedError {
    case activeChallengeExists
    case insufficientFunds(available: Decimal, required: Decimal)
    case withdrawalCooldownActive(remaining: TimeInterval)
    case notAParticipant
    case alreadyAParticipant
    case challengeNotFound
    case withdrawalNotFound
    case invalidChallengeStatus(
        current: Challenge.ChallengeStatus,
        expected: Challenge.ChallengeStatus
    )
    case networkError(underlying: Error)
    case decodingError
    case unauthorized
    case unknown

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .activeChallengeExists:
            return "A challenge is already active. Wait for it to end before creating another."

        case .insufficientFunds(let available, let required):
            let formattedAvailable = available.formatted(.currency(code: "BRL"))
            let formattedRequired = required.formatted(.currency(code: "BRL"))
            return "Insufficient funds. Available: \(formattedAvailable), required: \(formattedRequired)."

        case .withdrawalCooldownActive(let remaining):
            let hours = Int(remaining) / 3600
            let minutes = (Int(remaining) % 3600) / 60
            let seconds = Int(remaining) % 60
            return "Withdrawals locked. You recently won a challenge. Try again in \(String(format: "%02d:%02d:%02d", hours, minutes, seconds))."

        case .notAParticipant:
            return "You are not a participant in this challenge."

        case .alreadyAParticipant:
            return "You are already participating in this challenge."

        case .challengeNotFound:
            return "Challenge not found."

        case .withdrawalNotFound:
            return "Withdrawal request not found."

        case .invalidChallengeStatus(let current, let expected):
            return "Invalid operation. Challenge is \(current), expected \(expected)."

        case .networkError(let underlying):
            return "Network error: \(underlying.localizedDescription)"

        case .decodingError:
            return "Failed to decode server response."

        case .unauthorized:
            return "You are not authorized to perform this action."

        case .unknown:
            return "An unexpected error occurred."
        }
    }

    // MARK: - Helpers

    var isRetryable: Bool {
        switch self {
        case .networkError:
            return true
        default:
            return false
        }
    }
}
