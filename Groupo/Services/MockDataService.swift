import Foundation
import Combine

class MockDataService: ObservableObject {
    @Published var currentUser: User
    @Published var currentGroup: Group
    @Published var challenges: [Challenge]
    @Published var transactions: [Transaction]
    @Published var votes: [Vote] = []
    @Published var withdrawalRequests: [WithdrawalRequest] = []
    
    private let defaults = UserDefaults.standard
    private let keys = (
        user: "mock_user",
        group: "mock_group",
        challenges: "mock_challenges",
        transactions: "mock_transactions",
        votes: "mock_votes",
        withdrawals: "mock_withdrawals"
    )
    
    init() {
        self.currentUser = User(id: UUID(), name: "", avatar: "", reputationScore: 0, currentEquity: 0, challengesWon: 0, challengesLost: 0, lastWinTimestamp: nil, votingHistory: [], consecutiveMissedVotes: 0, status: .active)
        self.currentGroup = Group(id: UUID(), name: "", totalPool: 0, members: [])
        self.challenges = []
        self.transactions = []
        
        if !loadData() {
            initializeWithDefaultData()
        }
    }
    
    private func initializeWithDefaultData() {
        let user = User(
            id: UUID(),
            name: "João Silva",
            avatar: "person.circle.fill",
            reputationScore: 100,
            currentEquity: 500.00,
            challengesWon: 5,
            challengesLost: 2,
            lastWinTimestamp: nil,
            votingHistory: [],
            consecutiveMissedVotes: 0,
            status: .active
        )
        self.currentUser = user
        let member2 = User(id: UUID(), name: "Maria Oliveira", avatar: "person.circle", reputationScore: 90, currentEquity: 500.00, challengesWon: 3, challengesLost: 1, lastWinTimestamp: nil, votingHistory: [], consecutiveMissedVotes: 0, status: .active)
        let member3 = User(id: UUID(), name: "Carlos Pereira", avatar: "person.circle", reputationScore: 85, currentEquity: 500.00, challengesWon: 1, challengesLost: 4, lastWinTimestamp: nil, votingHistory: [], consecutiveMissedVotes: 0, status: .active)
        
        self.currentGroup = Group(
            id: UUID(),
            name: "Férias 2024",
            totalPool: 1500.00,
            members: [user, member2, member3]
        )
        
        self.challenges = [
        ]
        
        self.transactions = [
            Transaction(
                id: UUID(),
                description: "Vitoria Desafio Semanal",
                amount: 50.00,
                type: .win,
                timestamp: Date().addingTimeInterval(-60 * 60 * 2),
                relatedChallengeID: nil,
                splitDetails: nil
            ),
            Transaction(
                id: UUID(),
                description: "Depósito Inicial - João",
                amount: 500.00,
                type: .win,
                timestamp: Date().addingTimeInterval(-60 * 60 * 24 * 2),
                relatedChallengeID: nil,
                splitDetails: nil
            ),
            Transaction(
                id: UUID(),
                description: "Jantar de Comemoração",
                amount: 200.00,
                type: .expense,
                timestamp: Date().addingTimeInterval(-60 * 60 * 24 * 1),
                relatedChallengeID: nil,
                splitDetails: ["João Silva": 66.66, "Maria Oliveira": 66.67, "Carlos Pereira": 66.67]
            )
        ]
        
        
        saveData()
    }
    
    // MARK: - Persistence
    
    private func saveData() {
        if let encoded = try? JSONEncoder().encode(currentUser) {
            defaults.set(encoded, forKey: keys.user)
        }
        if let encoded = try? JSONEncoder().encode(currentGroup) {
            defaults.set(encoded, forKey: keys.group)
        }
        if let encoded = try? JSONEncoder().encode(challenges) {
            defaults.set(encoded, forKey: keys.challenges)
        }
        if let encoded = try? JSONEncoder().encode(transactions) {
            defaults.set(encoded, forKey: keys.transactions)
        }
        if let encoded = try? JSONEncoder().encode(votes) {
            defaults.set(encoded, forKey: keys.votes)
        }
        if let encoded = try? JSONEncoder().encode(withdrawalRequests) {
            defaults.set(encoded, forKey: keys.withdrawals)
        }
    }
    
    private func loadData() -> Bool {
        guard let userData = defaults.data(forKey: keys.user),
              let groupData = defaults.data(forKey: keys.group),
              let challengesData = defaults.data(forKey: keys.challenges),
              let transactionsData = defaults.data(forKey: keys.transactions) else {
            return false
        }
        
        do {
            let decoder = JSONDecoder()
            currentUser = try decoder.decode(User.self, from: userData)
            currentGroup = try decoder.decode(Group.self, from: groupData)
            challenges = try decoder.decode([Challenge].self, from: challengesData)
            transactions = try decoder.decode([Transaction].self, from: transactionsData)
            
            if let votesData = defaults.data(forKey: keys.votes) {
                votes = try decoder.decode([Vote].self, from: votesData)
            }
            
            if let withdrawalsData = defaults.data(forKey: keys.withdrawals) {
                withdrawalRequests = try decoder.decode([WithdrawalRequest].self, from: withdrawalsData)
            }
            
            return true
        } catch {
            print("Failed to decode saved data: \(error)")
            return false
        }
    }
    
    func resetData() {
        defaults.removeObject(forKey: keys.user)
        defaults.removeObject(forKey: keys.group)
        defaults.removeObject(forKey: keys.challenges)
        defaults.removeObject(forKey: keys.transactions)
        defaults.removeObject(forKey: keys.votes)
        defaults.removeObject(forKey: keys.withdrawals)
        
        initializeWithDefaultData()
    }
    
    func addExpense(amount: Decimal, description: String, splitDetails: [String: Decimal]? = nil) {
        let transaction = Transaction(
            id: UUID(),
            description: description,
            amount: amount,
            type: .expense,
            timestamp: Date(),
            relatedChallengeID: nil,
            splitDetails: splitDetails
        )
        transactions.insert(transaction, at: 0)
        
        let newPool = currentGroup.totalPool - amount
        currentGroup = Group(
            id: currentGroup.id,
            name: currentGroup.name,
            totalPool: newPool,
            members: currentGroup.members
        )
        
        saveData()
    }
    
    func castVote(targetID: UUID, type: Vote.VoteType, voterID: UUID? = nil) {
        let voter = voterID ?? currentUser.id
        
        // Remove existing vote if any
        if let existingIndex = votes.firstIndex(where: { $0.targetID == targetID && $0.voterID == voter }) {
            votes.remove(at: existingIndex)
        }
        
        let vote = Vote(
            id: UUID(),
            voterID: voter,
            targetID: targetID,
            type: type,
            deadline: Date().addingTimeInterval(60 * 60 * 24)
        )
        votes.append(vote)
        saveData()
        objectWillChange.send()
    }
    
    func updateVotingParticipation(for targetID: UUID) {
        var newMembers = currentGroup.members
        
        for (index, member) in newMembers.enumerated() {
            let hasVoted = votes.contains { $0.targetID == targetID && $0.voterID == member.id }
            
            var newHistory = member.votingHistory
            var newConsecutive = member.consecutiveMissedVotes
            var newStatus = member.status
            
            if hasVoted {
                if !newHistory.contains(targetID) {
                    newHistory.append(targetID)
                }
                newConsecutive = 0
            } else {
                newConsecutive += 1
                if newConsecutive >= 3 {
                    newStatus = .inactive
                }
            }
            
            newMembers[index] = User(
                id: member.id,
                name: member.name,
                avatar: member.avatar,
                reputationScore: member.reputationScore,
                currentEquity: member.currentEquity,
                challengesWon: member.challengesWon,
                challengesLost: member.challengesLost,
                lastWinTimestamp: member.lastWinTimestamp,
                votingHistory: newHistory,
                consecutiveMissedVotes: newConsecutive,
                status: newStatus
            )
        }
        
        currentGroup = Group(id: currentGroup.id, name: currentGroup.name, totalPool: currentGroup.totalPool, members: newMembers)
        
        if let updatedCurrentUser = newMembers.first(where: { $0.id == currentUser.id }) {
            currentUser = updatedCurrentUser
        }
        
        
        saveData()
    }
    
    var hasActiveChallenge: Bool {
        return challenges.contains { $0.status == .active || $0.status == .voting }
    }
    
    var activeChallenge: Challenge? {
        return challenges.first { $0.status == .active || $0.status == .voting }
    }
    
    func addChallenge(title: String, description: String, buyIn: Decimal, deadline: Date, validationMode: Challenge.ValidationMode = .proof) {
        if hasActiveChallenge {
            return
        }
        
        guard currentUserAvailableBalance >= buyIn else {
            print("Insufficient funds to create challenge with buy-in \(buyIn)")
            return
        }
        
        var newChallenge = Challenge(
            id: UUID(),
            title: title,
            description: description,
            buyIn: buyIn,
            createdDate: Date(),
            deadline: deadline,
            participants: [currentUser.id],
            status: .active
        )
        newChallenge.validationMode = validationMode
        challenges.insert(newChallenge, at: 0)
        
        saveData()
    }
    
    func startVoting(challengeID: UUID) {
        guard let index = challenges.firstIndex(where: { $0.id == challengeID }) else { return }
        var challenge = challenges[index]
        
        guard challenge.status == .active else { return }
        
        challenge.status = .voting
        
        challenges[index] = challenge
        saveData()
        objectWillChange.send()
    }
    
    var currentUserFrozenBalance: Decimal {
        let activeChallenges = challenges.filter {
            ($0.status == .active || $0.status == .voting) &&
            $0.participants.contains(currentUser.id)
        }
        return activeChallenges.reduce(0) { $0 + $1.buyIn }
    }
    
    var currentUserAvailableBalance: Decimal {
        return currentUser.currentEquity - currentUserFrozenBalance
    }
    
    func requestWithdrawal(amount: Decimal) {
        let request = WithdrawalRequest(
            id: UUID(),
            initiatorID: currentUser.id,
            amount: amount,
            status: .pending,
            createdDate: Date(),
            deadline: Date().addingTimeInterval(60 * 60 * 24)
        )
        withdrawalRequests.insert(request, at: 0)
        
        saveData()
    }
    
    func joinChallenge(challengeID: UUID) {
        guard let index = challenges.firstIndex(where: { $0.id == challengeID }) else { return }
        var challenge = challenges[index]
        
        if !challenge.participants.contains(currentUser.id) {
            guard currentUserAvailableBalance >= challenge.buyIn else {
                print("Insufficient funds to join challenge")
                return
            }
            
            challenge.participants.append(currentUser.id)
            challenges[index] = challenge
            
            saveData()
            objectWillChange.send()
        }
    }
    
    func submitProof(challengeID: UUID, image: String?) {
        guard let index = challenges.firstIndex(where: { $0.id == challengeID }) else { return }
        var challenge = challenges[index]
        
        guard challenge.status == .active else { return }
        
        challenge.proofImage = image
        challenge.proofSubmissionUserID = currentUser.id
        challenge.status = .voting
        
        challenges[index] = challenge
        saveData()
        objectWillChange.send()
    }
    
    func resolveChallengeVoting(challengeID: UUID) {
        guard let index = challenges.firstIndex(where: { $0.id == challengeID }) else { return }
        var challenge = challenges[index]
        
        guard challenge.status == .voting else { return }
        
        updateVotingParticipation(for: challengeID)
        
        let challengeVotes = votes.filter { $0.targetID == challengeID }
        let totalMembers = currentGroup.members.count
        
        // Edge Case: No votes cast
        if challengeVotes.isEmpty {
            challenge.status = .failed
            challenge.votingFailureReason = "No votes cast. Funds refunded."
            refundChallenge(challenge)
            challenges[index] = challenge
            saveData()
            objectWillChange.send()
            return
        }
        
        // Requirements
        let participationCount = challengeVotes.count
        let participationThreshold = Int(ceil(Double(totalMembers) * 0.5)) // 50% participation required
        
        // Edge Case: Minimum participation not met
        if participationCount < participationThreshold {
            challenge.status = .failed
            challenge.votingFailureReason = "Insufficient participation (\(participationCount)/\(totalMembers)). Funds refunded."
            refundChallenge(challenge)
            challenges[index] = challenge
            saveData()
            objectWillChange.send()
            return
        }
        
        let approvalVotes = challengeVotes.filter { $0.type == .approval }.count
        let contestVotes = challengeVotes.filter { $0.type == .contest }.count
        
        // Edge Case: Tie
        if approvalVotes == contestVotes {
            challenge.status = .failed
            challenge.votingFailureReason = "Tie vote (\(approvalVotes) vs \(contestVotes)). Funds refunded."
            refundChallenge(challenge)
            challenges[index] = challenge
            saveData()
            objectWillChange.send()
            return
        }
        
        if approvalVotes > contestVotes {
            challenge.status = .complete
            
            let pot = challenge.buyIn * Decimal(challenge.participants.count)
            let winnerID = challenge.proofSubmissionUserID ?? currentUser.id
            
            if winnerID == currentUser.id {
                let profit = pot - challenge.buyIn
                updateUserStats(win: true, profit: profit)
                
                let winTransaction = Transaction(
                    id: UUID(),
                    description: "Vitoria: \(challenge.title)",
                    amount: profit,
                    type: .win,
                    timestamp: Date(),
                    relatedChallengeID: challenge.id,
                    splitDetails: nil
                )
                transactions.insert(winTransaction, at: 0)
            } else if challenge.participants.contains(currentUser.id) {
                updateUserStats(win: false, profit: 0, buyIn: challenge.buyIn)
                
                let lossTransaction = Transaction(
                    id: UUID(),
                    description: "Derrota: \(challenge.title)",
                    amount: challenge.buyIn,
                    type: .expense,
                    timestamp: Date(),
                    relatedChallengeID: challenge.id,
                    splitDetails: nil
                )
                transactions.insert(lossTransaction, at: 0)
            }
        } else {
            challenge.status = .failed
            challenge.votingFailureReason = "Challenge contested by majority. Funds refunded."
            refundChallenge(challenge)
        }
        
        challenges[index] = challenge
        saveData()
        objectWillChange.send()
    }
    
    private func refundChallenge(_ challenge: Challenge) {
        if challenge.participants.contains(currentUser.id) {
            // Refund logic: User gets buy-in back (visual representation of unfreezing funds)
        }
        
        // Only create transaction if user was a participant
        if challenge.participants.contains(currentUser.id) {
            let refundTransaction = Transaction(
                id: UUID(),
                description: "Reembolso: \(challenge.title)",
                amount: challenge.buyIn, 
                type: .refund,
                timestamp: Date(),
                relatedChallengeID: challenge.id,
                splitDetails: nil
            )
            transactions.insert(refundTransaction, at: 0)
        }
    }
    
    private func updateUserStats(win: Bool, profit: Decimal, buyIn: Decimal = 0) {
        if win {
            currentUser = User(
                id: currentUser.id,
                name: currentUser.name,
                avatar: currentUser.avatar,
                reputationScore: currentUser.reputationScore + 10,
                currentEquity: currentUser.currentEquity + profit,
                challengesWon: currentUser.challengesWon + 1,
                challengesLost: currentUser.challengesLost,
                lastWinTimestamp: Date(),
                votingHistory: currentUser.votingHistory,
                consecutiveMissedVotes: currentUser.consecutiveMissedVotes,
                status: currentUser.status
            )
        } else {
            currentUser = User(
                id: currentUser.id,
                name: currentUser.name,
                avatar: currentUser.avatar,
                reputationScore: currentUser.reputationScore,
                currentEquity: currentUser.currentEquity - buyIn, // Deduct the loss
                challengesWon: currentUser.challengesWon,
                challengesLost: currentUser.challengesLost + 1,
                lastWinTimestamp: currentUser.lastWinTimestamp,
                votingHistory: currentUser.votingHistory,
                consecutiveMissedVotes: currentUser.consecutiveMissedVotes,
                status: currentUser.status
            )
        }
    }
    
    func completeChallenge(challengeID: UUID, winnerID: UUID?) {
        resolveChallengeVoting(challengeID: challengeID)
    }
    
    // MARK: - Withdrawal Auto-Approval Logic (Antifragile)
    
    func verifyExpiredWithdrawals() {
        let now = Date()
        let expiredPending = withdrawalRequests.filter { $0.status == .pending && $0.deadline < now }
        
        for request in expiredPending {
            autoApproveWithdrawal(request)
        }
    }
    
    private func autoApproveWithdrawal(_ request: WithdrawalRequest) {
        guard let index = withdrawalRequests.firstIndex(where: { $0.id == request.id }) else { return }
        
        let requestVotes = votes.filter { $0.targetID == request.id }
        let contestVotes = requestVotes.filter { $0.type == .contest }.count
        let totalMembers = currentGroup.members.count
        let requiredContestVotes = (totalMembers / 2) + 1
        
        if contestVotes < requiredContestVotes {
            var updatedRequest = request
            updatedRequest.status = .approved
            withdrawalRequests[index] = updatedRequest
            
            updateVotingParticipation(for: request.id)
            
            let newPool = currentGroup.totalPool - request.amount
            currentGroup = Group(
                id: currentGroup.id,
                name: currentGroup.name,
                totalPool: newPool,
                members: currentGroup.members
            )
            
            if let userIndex = currentGroup.members.firstIndex(where: { $0.id == request.initiatorID }) {
                var member = currentGroup.members[userIndex]
                member = User(
                    id: member.id,
                    name: member.name,
                    avatar: member.avatar,
                    reputationScore: member.reputationScore,
                    currentEquity: member.currentEquity - request.amount, // Deduct
                    challengesWon: member.challengesWon,
                    challengesLost: member.challengesLost,
                    lastWinTimestamp: member.lastWinTimestamp,
                    votingHistory: member.votingHistory,
                    consecutiveMissedVotes: member.consecutiveMissedVotes,
                    status: member.status
                )
                
                var newMembers = currentGroup.members
                newMembers[userIndex] = member
                
                currentGroup = Group(
                    id: currentGroup.id,
                    name: currentGroup.name,
                    totalPool: currentGroup.totalPool,
                    members: newMembers
                )
                
                if member.id == currentUser.id {
                    currentUser = member
                }
            }
            
            let transaction = Transaction(
                id: UUID(),
                description: "Withdrawal Approved (Auto)",
                amount: request.amount,
                type: .withdrawal,
                timestamp: Date(),
                relatedChallengeID: nil,
                splitDetails: nil
            )
            transactions.insert(transaction, at: 0)
            
            print("Auto-approved withdrawal \(request.id)")
            saveData()
            objectWillChange.send()
        } else {
            var updatedRequest = request
            updatedRequest.status = .rejected
            withdrawalRequests[index] = updatedRequest
            saveData()
            objectWillChange.send()
        }
    }
}

// MARK: - Preview Helper
extension MockDataService {
    static var preview: MockDataService {
        let service = MockDataService()
        if service.currentUser.name.isEmpty {
            service.resetData()
        }
        return service
    }
    
    static var empty: MockDataService {
        let service = MockDataService()
        service.currentUser = User(id: UUID(), name: "New User", avatar: "person.circle", reputationScore: 0, currentEquity: 0, challengesWon: 0, challengesLost: 0, lastWinTimestamp: nil, votingHistory: [], consecutiveMissedVotes: 0, status: .active)
        service.currentGroup = Group(id: UUID(), name: "New Group", totalPool: 0, members: [])
        service.challenges = []
        service.transactions = []
        service.votes = []
        service.withdrawalRequests = []
        return service
    }
    
    static var loading: MockDataService {
        let service = MockDataService()
        return service
    }
}
