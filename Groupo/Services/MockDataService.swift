import Foundation
import Combine

class MockDataService: ObservableObject {
    @Published var currentUser: User
    @Published var currentGroup: Group
    @Published var challenges: [Challenge]
    @Published var transactions: [Transaction]
    @Published var votes: [Vote] = []
    @Published var withdrawalRequests: [WithdrawalRequest] = []
    
    init() {
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
            Challenge(
                id: UUID(),
                title: "Economizar R$ 50 na semana",
                description: "Quem conseguir economizar mais, ganha.",
                buyIn: 50.00,
                deadline: Date().addingTimeInterval(60 * 60 * 24 * 7),
                participants: [user.id, member2.id],
                status: .active
            ),
            Challenge(
                id: UUID(),
                title: "Sem Uber por 1 mês",
                description: "Ninguém pode usar Uber, apenas transporte público ou caminhada.",
                buyIn: 500.00,
                deadline: Date().addingTimeInterval(60 * 60 * 24 * 30),
                participants: [],
                status: .voting
            )
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
    }
    
    func addExpense(amount: Decimal, description: String) {
        let transaction = Transaction(
            id: UUID(),
            description: description,
            amount: amount,
            type: .expense,
            timestamp: Date(),
            relatedChallengeID: nil,
            splitDetails: nil
        )
        transactions.insert(transaction, at: 0)
        
        let newPool = currentGroup.totalPool - amount
        currentGroup = Group(
            id: currentGroup.id,
            name: currentGroup.name,
            totalPool: newPool,
            members: currentGroup.members
        )
    }
    
    func castVote(targetID: UUID, type: Vote.VoteType, voterID: UUID? = nil) {
        let vote = Vote(
            id: UUID(),
            voterID: voterID ?? currentUser.id,
            targetID: targetID,
            type: type,
            deadline: Date().addingTimeInterval(60 * 60 * 24)
        )
        votes.append(vote)
        
        // Reset consecutive missed votes if they vote
        if let index = currentGroup.members.firstIndex(where: { $0.id == (voterID ?? currentUser.id) }) {
            var member = currentGroup.members[index]
            member = User(
                id: member.id,
                name: member.name,
                avatar: member.avatar,
                reputationScore: member.reputationScore,
                currentEquity: member.currentEquity,
                challengesWon: member.challengesWon,
                challengesLost: member.challengesLost,
                lastWinTimestamp: member.lastWinTimestamp,
                votingHistory: member.votingHistory,
                consecutiveMissedVotes: 0, 
                status: member.status == .inactive ? .active : member.status // Reactivate if active?
            )
            var newMembers = currentGroup.members
            newMembers[index] = member
            currentGroup = Group(id: currentGroup.id, name: currentGroup.name, totalPool: currentGroup.totalPool, members: newMembers)
            
            if member.id == currentUser.id {
                currentUser = member
            }
        }
        
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
    }
    
    var hasActiveChallenge: Bool {
        return challenges.contains { $0.status == .active || $0.status == .voting }
    }
    
    var activeChallenge: Challenge? {
        return challenges.first { $0.status == .active || $0.status == .voting }
    }
    
    func addChallenge(title: String, description: String, buyIn: Decimal, deadline: Date) {
        if hasActiveChallenge {
            return
        }
        
        guard currentUserAvailableBalance >= buyIn else {
            print("Insufficient funds to create challenge with buy-in \(buyIn)")
            return
        }
        
        let newChallenge = Challenge(
            id: UUID(),
            title: title,
            description: description,
            buyIn: buyIn,
            deadline: deadline,
            participants: [currentUser.id],
            status: .active
        )
        challenges.insert(newChallenge, at: 0)
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
        objectWillChange.send()
    }
    
    func resolveChallengeVoting(challengeID: UUID) {
        guard let index = challenges.firstIndex(where: { $0.id == challengeID }) else { return }
        var challenge = challenges[index]
        
        guard challenge.status == .voting else { return }
        
        updateVotingParticipation(for: challengeID)
        
        let challengeVotes = votes.filter { $0.targetID == challengeID }
        let approvalVotes = challengeVotes.filter { $0.type == .approval }.count
        
        let requiredVotes = (challenge.participants.count / 2) + 1
        
        if approvalVotes >= requiredVotes {
            challenge.status = .complete
            
            let pot = challenge.buyIn * Decimal(challenge.participants.count)
            let winnerID = challenge.proofSubmissionUserID ?? currentUser.id
            
            if winnerID == currentUser.id {
                let profit = pot - challenge.buyIn
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
                currentUser = User(
                    id: currentUser.id,
                    name: currentUser.name,
                    avatar: currentUser.avatar,
                    reputationScore: currentUser.reputationScore,
                    currentEquity: currentUser.currentEquity - challenge.buyIn,
                    challengesWon: currentUser.challengesWon,
                    challengesLost: currentUser.challengesLost + 1,
                    lastWinTimestamp: currentUser.lastWinTimestamp,
                    votingHistory: currentUser.votingHistory,
                    consecutiveMissedVotes: currentUser.consecutiveMissedVotes,
                    status: currentUser.status
                )
                
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
            
            if challenge.participants.contains(currentUser.id) {
                
            }
            
            let refundTransaction = Transaction(
                id: UUID(),
                description: "Reembolso: \(challenge.title)",
                amount: 0,
                type: .win,
                timestamp: Date(),
                relatedChallengeID: challenge.id,
                splitDetails: nil
            )
            transactions.insert(refundTransaction, at: 0)
        }
        
        challenges[index] = challenge
        objectWillChange.send()
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
            objectWillChange.send()
        } else {
            var updatedRequest = request
            updatedRequest.status = .rejected
            withdrawalRequests[index] = updatedRequest
            objectWillChange.send()
        }
    }
}
