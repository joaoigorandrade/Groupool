import Foundation
import Combine

class MockDataService: ObservableObject {
    @Published var currentUser: User
    @Published var currentGroup: Group
    @Published var challenges: [Challenge]
    @Published var transactions: [Transaction]
    @Published var votes: [Vote] = []

    init() {
        // Mock User
        let user = User(
            id: UUID(),
            name: "João Silva",
            avatar: "person.circle.fill", // SF Symbol
            reputationScore: 100,
            status: .active
        )
        self.currentUser = user

        // Mock Group Members
        let member2 = User(id: UUID(), name: "Maria Oliveira", avatar: "person.circle", reputationScore: 90, status: .active)
        let member3 = User(id: UUID(), name: "Carlos Pereira", avatar: "person.circle", reputationScore: 85, status: .active)

        // Mock Group
        self.currentGroup = Group(
            id: UUID(),
            name: "Férias 2024",
            totalPool: 1500.00,
            members: [user, member2, member3]
        )

        // Mock Challenges
        self.challenges = [
            Challenge(
                id: UUID(),
                title: "Economizar R$ 50 na semana",
                buyIn: 50.00,
                deadline: Date().addingTimeInterval(60 * 60 * 24 * 7), // 7 days from now
                status: .active
            ),
            Challenge(
                id: UUID(),
                title: "Sem Uber por 1 mês",
                buyIn: 100.00,
                deadline: Date().addingTimeInterval(60 * 60 * 24 * 30), // 30 days from now
                status: .voting
            )
        ]

        // Mock Transactions
        self.transactions = [
            Transaction(
                id: UUID(),
                description: "Depósito Inicial - João",
                amount: 500.00,
                type: .win, // Using 'win' as positive inflow for now if 'deposit' isn't available, or it should be 'expense' is negative? Let's check TransactionType.
                // Checking Transaction.swift: expense, withdrawal, win.
                // 'win' likely adds to pool. 'expense' likely subtracts? Or 'expense' is a group expense?
                // Let's assume 'win' adds money (like winning a challenge) and 'expense' spends it.
                // For a deposit, it might be a 'win' or we might need a 'deposit' case. 
                // Given the enum: expense, withdrawal, win. I'll use 'win' for income for now, or maybe the user meant something else.
                // Let's stick to the visible types. 
                timestamp: Date().addingTimeInterval(-60 * 60 * 24 * 2) // 2 days ago
            ),
             Transaction(
                id: UUID(),
                description: "Jantar de Comemoração",
                amount: 200.00,
                type: .expense,
                timestamp: Date().addingTimeInterval(-60 * 60 * 24 * 1) // 1 day ago
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
        
        // Update group total pool?
        // If it sends money OUT of the pool
        // currentGroup.totalPool -= amount // Group struct is immutable (let properties).
        // I need to update the group object.
        
        // Since Group is a struct and members are let, I might need to create a new Group with updated pool.
        // However, Group struct definition: let totalPool: Decimal.
        // I cannot modify it directly. I have to replace `currentGroup`.
        
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
            deadline: Date().addingTimeInterval(60 * 60 * 24) // 24 hours deadline
        )
        votes.append(vote)
    }
}
