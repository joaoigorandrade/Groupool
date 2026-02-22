import Combine
import Foundation
import Observation
import SwiftUI

@Observable
final class TreasuryViewModel {
    // MARK: - State
    var activeItems: [GovernanceItem] = []
    var sections: [TransactionSection] = []
    var dailySummaries: [DailySummary] = []
    var currentUser: User?
    var currentTime: Date = Date()
    var isLoading: Bool = false
    var errorMessage: String?
    
    // MARK: - Properties
    private var currentGroup: Group?
    private var latestVotes: [Vote] = []
    private var hasLoadedLedger = false
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Dependencies
    private let transactionUseCase: TreasuryTransactionUseCaseProtocol
    private let challengeUseCase: TreasuryChallengeUseCaseProtocol
    private let voteUseCase: TreasuryVoteUseCaseProtocol
    private let withdrawalUseCase: TreasuryWithdrawalUseCaseProtocol
    private let groupUseCase: TreasuryGroupUseCaseProtocol
    private let userUseCase: TreasuryUserUseCaseProtocol
    
    init(
        transactionUseCase: TreasuryTransactionUseCaseProtocol,
        challengeUseCase: TreasuryChallengeUseCaseProtocol,
        voteUseCase: TreasuryVoteUseCaseProtocol,
        withdrawalUseCase: TreasuryWithdrawalUseCaseProtocol,
        groupUseCase: TreasuryGroupUseCaseProtocol,
        userUseCase: TreasuryUserUseCaseProtocol
    ) {
        self.transactionUseCase = transactionUseCase
        self.challengeUseCase = challengeUseCase
        self.voteUseCase = voteUseCase
        self.withdrawalUseCase = withdrawalUseCase
        self.groupUseCase = groupUseCase
        self.userUseCase = userUseCase
        
        setupSubscribers()
        setupTimer()
    }
    
    @MainActor
    func refresh() async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isLoading = false
    }
    
    // MARK: - Subscribers
    
    private func setupSubscribers() {
        // Governance Items (Challenges + Withdrawals)
        Publishers.CombineLatest(challengeUseCase.challenges, withdrawalUseCase.withdrawalRequests)
            .receive(on: DispatchQueue.main)
            .map { (challenges, withdrawals) -> [GovernanceItem] in
                var items: [GovernanceItem] = []
                let activeChallenges = challenges.filter { $0.status == .active || $0.status == .voting }
                items.append(contentsOf: activeChallenges.map { GovernanceItem.challenge($0) })
                let pendingWithdrawals = withdrawals.filter { $0.status == .pending }
                items.append(contentsOf: pendingWithdrawals.map { GovernanceItem.withdrawal($0) })
                return items.sorted { $0.deadline < $1.deadline }
            }
            .sink { [weak self] items in
                self?.activeItems = items
            }
            .store(in: &cancellables)
            
        // User & Group data
        userUseCase.currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in self?.currentUser = user }
            .store(in: &cancellables)
            
        groupUseCase.currentGroup
            .receive(on: DispatchQueue.main)
            .sink { [weak self] group in self?.currentGroup = group }
            .store(in: &cancellables)
            
        voteUseCase.votes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] votes in self?.latestVotes = votes }
            .store(in: &cancellables)
            
        // Ledger data
        transactionUseCase.transactions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] transactions in
                guard let self else { return }
                if !hasLoadedLedger {
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                        processTransactions(transactions)
                        hasLoadedLedger = true
                    }
                } else {
                    processTransactions(transactions)
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupTimer() {
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.currentTime = Date()
                Task { [weak self] in
                    await self?.withdrawalUseCase.verifyExpiredWithdrawals()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    @MainActor
    func castVote(challenge: Challenge, type: Vote.VoteType) async {
        isLoading = true
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            try await voteUseCase.castVote(targetID: challenge.id, type: type)
            HapticManager.notificationSuccess()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    @MainActor
    func castVote(withdrawal: WithdrawalRequest, type: Vote.VoteType) async {
        isLoading = true
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            try await voteUseCase.castVote(targetID: withdrawal.id, type: type)
            HapticManager.notificationSuccess()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    @MainActor
    func joinChallenge(challenge: Challenge) async {
        isLoading = true
         do {
            try await challengeUseCase.joinChallenge(id: challenge.id)
            HapticManager.notificationSuccess()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    @MainActor
    func startVoting(challenge: Challenge) async {
        isLoading = true
        do {
            try await challengeUseCase.startVoting(challengeID: challenge.id)
            HapticManager.notificationSuccess()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    @MainActor
    func resolveChallenge(challenge: Challenge) async {
        isLoading = true
        do {
            try await challengeUseCase.resolveVoting(challengeID: challenge.id)
            HapticManager.notificationSuccess()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func getUser(for id: UUID) -> User? {
        // This is a bit inefficient but for demo/mock it works. 
        // In a real app we'd have a user cache or fetch.
        return currentGroup?.members.first { $0.id == id } ?? (currentUser?.id == id ? currentUser : nil)
    }
    
    @MainActor
    func castVote(withdrawal: WithdrawalRequest, type: Vote.VoteType, reason: String? = nil) async {
        isLoading = true
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            try await voteUseCase.castVote(targetID: withdrawal.id, type: type)
            // Note: reason is currently not supported by voteService
            HapticManager.notificationSuccess()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    // MARK: - Helpers
    
    private func processTransactions(_ transactions: [Transaction]) {
        let sortedTransactions = transactions.sorted { $0.timestamp > $1.timestamp }
        let grouped = Dictionary(grouping: sortedTransactions) { (transaction) -> Date in
            let components = Calendar.current.dateComponents([.year, .month], from: transaction.timestamp)
            return Calendar.current.date(from: components) ?? transaction.timestamp
        }
        let sortedKeys = grouped.keys.sorted(by: >)
        self.sections = sortedKeys.map { date in
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "pt_BR")
            formatter.dateFormat = "MMM yyyy"
            let title = formatter.string(from: date).capitalized
            return TransactionSection(title: title, transactions: grouped[date] ?? [])
        }
        generateDailySummaries(from: transactions)
    }
    
    private func generateDailySummaries(from transactions: [Transaction]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var summaries: [DailySummary] = []
        for i in 0..<60 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let dayTransactions = transactions.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
            var netAmount: Decimal = 0
            for tx in dayTransactions {
                switch tx.type {
                case .win, .refund: netAmount += tx.amount
                case .expense, .withdrawal: netAmount -= tx.amount
                }
            }
            summaries.append(DailySummary(date: date, netAmount: netAmount, transactionCount: dayTransactions.count))
        }
        self.dailySummaries = summaries.reversed()
    }
    
    func timeRemaining(for deadline: Date) -> String {
        let remaining = deadline.timeIntervalSince(currentTime)
        if remaining <= 0 { return "Expired" }
        let days = Int(remaining) / (3600 * 24)
        if days > 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            return formatter.string(from: deadline)
        } else if days >= 1 {
            let hours = Int(remaining) / 3600 % 24
            let minutes = Int(remaining) / 60 % 60
            let seconds = Int(remaining) % 60
            return String(format: "%d days and %02d:%02d:%02d", days, hours, minutes, seconds)
        } else {
            let hours = Int(remaining) / 3600
            let minutes = Int(remaining) / 60 % 60
            let seconds = Int(remaining) % 60
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
    }
    
    func progress(for item: GovernanceItem) -> Double {
        let totalDuration = item.deadline.timeIntervalSince(item.createdDate)
        let elapsed = currentTime.timeIntervalSince(item.createdDate)
        guard totalDuration > 0 else { return 1.0 }
        return min(max(elapsed / totalDuration, 0.0), 1.0)
    }
    
    func hasVoted(on item: GovernanceItem) -> Bool {
        guard let userId = currentUser?.id else { return false }
        return latestVotes.contains { $0.targetID == item.id && $0.voterID == userId }
    }
    
    func isEligibleToVote(on item: GovernanceItem) -> Bool {
        guard let userId = currentUser?.id else { return false }
        switch item {
        case .challenge(let challenge):
            return challenge.participants.contains(userId)
        case .withdrawal:
            return true
        }
    }
}
