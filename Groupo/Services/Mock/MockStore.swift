// MockStore.swift

import Combine
import Foundation

final class MockStore {

    // MARK: - State

    @Published var currentUser: User
    @Published var currentGroup: Group
    @Published var challenges: [Challenge]
    @Published var transactions: [Transaction]
    @Published var votes: [Vote]
    @Published var withdrawalRequests: [WithdrawalRequest]

    // MARK: - Private

    private let persistenceEnabled: Bool
    private let defaults = UserDefaults.standard

    private let keyUser = "mock_user"
    private let keyGroup = "mock_group"
    private let keyChallenges = "mock_challenges"
    private let keyTransactions = "mock_transactions"
    private let keyVotes = "mock_votes"
    private let keyWithdrawals = "mock_withdrawals"

    // MARK: - Init

    /// Creates a mock store.
    /// - Parameters:
    ///   - seed: Initial data to populate the store with.
    ///   - persistenceEnabled: When `true` (default), state is persisted to
    ///     `UserDefaults` and restored on next launch. Set to `false` for
    ///     SwiftUI previews to guarantee deterministic, side-effect-free state.
    init(seed: MockSeed = .default, persistenceEnabled: Bool = true) {
        self.persistenceEnabled = persistenceEnabled

        // Temporary values so all stored properties are set before `self` use.
        self.currentUser = seed.user
        self.currentGroup = seed.group
        self.challenges = seed.challenges
        self.transactions = seed.transactions
        self.votes = seed.votes
        self.withdrawalRequests = seed.withdrawalRequests

        if persistenceEnabled, !load() {
            apply(seed)
        }
    }

    // MARK: - Persistence

    func save() {
        guard persistenceEnabled else { return }
        let encoder = JSONEncoder()

        if let data = try? encoder.encode(currentUser) {
            defaults.set(data, forKey: keyUser)
        }
        if let data = try? encoder.encode(currentGroup) {
            defaults.set(data, forKey: keyGroup)
        }
        if let data = try? encoder.encode(challenges) {
            defaults.set(data, forKey: keyChallenges)
        }
        if let data = try? encoder.encode(transactions) {
            defaults.set(data, forKey: keyTransactions)
        }
        if let data = try? encoder.encode(votes) {
            defaults.set(data, forKey: keyVotes)
        }
        if let data = try? encoder.encode(withdrawalRequests) {
            defaults.set(data, forKey: keyWithdrawals)
        }
    }

    func load() -> Bool {
        guard let userData = defaults.data(forKey: keyUser),
              let groupData = defaults.data(forKey: keyGroup),
              let challengesData = defaults.data(forKey: keyChallenges),
              let transactionsData = defaults.data(forKey: keyTransactions)
        else {
            return false
        }

        do {
            let decoder = JSONDecoder()
            currentUser = try decoder.decode(User.self, from: userData)
            currentGroup = try decoder.decode(Group.self, from: groupData)
            challenges = try decoder.decode([Challenge].self, from: challengesData)
            transactions = try decoder.decode([Transaction].self, from: transactionsData)

            if let votesData = defaults.data(forKey: keyVotes) {
                votes = try decoder.decode([Vote].self, from: votesData)
            }

            if let withdrawalsData = defaults.data(forKey: keyWithdrawals) {
                withdrawalRequests = try decoder.decode(
                    [WithdrawalRequest].self,
                    from: withdrawalsData
                )
            }

            return true
        } catch {
            print("Failed to decode: \(error)")
            return false
        }
    }

    func reset(to seed: MockSeed = .default) {
        defaults.removeObject(forKey: keyUser)
        defaults.removeObject(forKey: keyGroup)
        defaults.removeObject(forKey: keyChallenges)
        defaults.removeObject(forKey: keyTransactions)
        defaults.removeObject(forKey: keyVotes)
        defaults.removeObject(forKey: keyWithdrawals)

        apply(seed)
    }

    private func apply(_ seed: MockSeed) {
        currentUser = seed.user
        currentGroup = seed.group
        challenges = seed.challenges
        transactions = seed.transactions
        votes = seed.votes
        withdrawalRequests = seed.withdrawalRequests
    }

    // MARK: - Computed Helpers

    var hasActiveChallenge: Bool {
        challenges.contains { $0.status == .active || $0.status == .voting }
    }

    var activeChallenge: Challenge? {
        challenges.first { $0.status == .active || $0.status == .voting }
    }

    var currentUserFrozenBalance: Decimal {
        challenges
            .filter {
                ($0.status == .active || $0.status == .voting)
                    && $0.participants.contains(currentUser.id)
            }
            .reduce(0) { $0 + $1.buyIn }
    }

    var currentUserAvailableBalance: Decimal {
        currentUser.currentEquity - currentUserFrozenBalance
    }
}
