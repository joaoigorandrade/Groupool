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
            status: .active
        )
        self.currentUser = user
        let member2 = User(id: UUID(), name: "Maria Oliveira", avatar: "person.circle", reputationScore: 90, currentEquity: 500.00, challengesWon: 3, challengesLost: 1, status: .active)
        let member3 = User(id: UUID(), name: "Carlos Pereira", avatar: "person.circle", reputationScore: 85, currentEquity: 500.00, challengesWon: 1, challengesLost: 4, status: .active)

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
                timestamp: Date().addingTimeInterval(-60 * 60 * 2)
            ),
             Transaction(
                id: UUID(),
                description: "Depósito Inicial - João",
                amount: 500.00,
                type: .win,
                timestamp: Date().addingTimeInterval(-60 * 60 * 24 * 2)
            ),
             Transaction(
                id: UUID(),
                description: "Jantar de Comemoração",
                amount: 200.00,
                type: .expense,
                timestamp: Date().addingTimeInterval(-60 * 60 * 24 * 1)
            )
        ]
    }

    func addExpense(amount: Decimal, description: String) {
        let transaction = Transaction(
            id: UUID(),
            description: description,
            amount: amount,
            type: .expense,
            timestamp: Date()
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

    func castVote(targetID: UUID, type: Vote.VoteType) {
        let vote = Vote(
            id: UUID(),
            targetID: targetID,
            type: type,
            deadline: Date().addingTimeInterval(60 * 60 * 24)
        )
        votes.append(vote)
    }

    var hasActiveChallenge: Bool {
        return challenges.contains { $0.status == .active }
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
            deadline: Date().addingTimeInterval(60 * 60 * 24) // 24 hours
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
    
    func completeChallenge(challengeID: UUID, winnerID: UUID?) {
        guard let index = challenges.firstIndex(where: { $0.id == challengeID }) else { return }
        var challenge = challenges[index]
        
        guard challenge.status != .complete else { return }
        
        challenge.status = .complete
        challenges[index] = challenge
        
        let pot = challenge.buyIn * Decimal(challenge.participants.count)
        
        if let winnerID = winnerID {
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
                    status: currentUser.status
                )
                
                let winTransaction = Transaction(
                    id: UUID(),
                    description: "Vitoria: \(challenge.title)",
                    amount: profit,
                    type: .win,
                    timestamp: Date()
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
                    status: currentUser.status
                )
                
                let lossTransaction = Transaction(
                    id: UUID(),
                    description: "Derrota: \(challenge.title)",
                    amount: challenge.buyIn,
                    type: .expense,
                    timestamp: Date()
                )
                transactions.insert(lossTransaction, at: 0)
            }
        }
        
        objectWillChange.send()
    }
}
