// MockSeed.swift

import Foundation

struct MockSeed {
    let user: User
    let group: Group
    let challenges: [Challenge]
    let transactions: [Transaction]
    let votes: [Vote]
    let withdrawalRequests: [WithdrawalRequest]
}

// MARK: - Static Instances

extension MockSeed {

    static let `default`: MockSeed = {
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

        let member2 = User(
            id: UUID(),
            name: "Maria Oliveira",
            avatar: "person.circle",
            reputationScore: 90,
            currentEquity: 500.00,
            challengesWon: 3,
            challengesLost: 1,
            lastWinTimestamp: nil,
            votingHistory: [],
            consecutiveMissedVotes: 0,
            status: .active
        )

        let member3 = User(
            id: UUID(),
            name: "Carlos Pereira",
            avatar: "person.circle",
            reputationScore: 85,
            currentEquity: 500.00,
            challengesWon: 1,
            challengesLost: 4,
            lastWinTimestamp: nil,
            votingHistory: [],
            consecutiveMissedVotes: 0,
            status: .active
        )

        let group = Group(
            id: UUID(),
            name: "Férias 2024",
            totalPool: 1500.00,
            members: [user, member2, member3]
        )

        let transactions: [Transaction] = [
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
                splitDetails: [
                    "João Silva": 66.66,
                    "Maria Oliveira": 66.67,
                    "Carlos Pereira": 66.67
                ]
            )
        ]

        return MockSeed(
            user: user,
            group: group,
            challenges: [],
            transactions: transactions,
            votes: [],
            withdrawalRequests: []
        )
    }()

    static let empty = MockSeed(
        user: User(
            id: UUID(),
            name: "New User",
            avatar: "person.circle",
            reputationScore: 0,
            currentEquity: 0,
            challengesWon: 0,
            challengesLost: 0,
            lastWinTimestamp: nil,
            votingHistory: [],
            consecutiveMissedVotes: 0,
            status: .active
        ),
        group: Group(
            id: UUID(),
            name: "New Group",
            totalPool: 0,
            members: []
        ),
        challenges: [],
        transactions: [],
        votes: [],
        withdrawalRequests: []
    )

    static let activeChallenge: MockSeed = {
        let base = MockSeed.default
        let challenge = Challenge(
            id: UUID(),
            title: "Weekly Pushups",
            description: "100 pushups before Sunday",
            buyIn: 50.00,
            createdDate: Date(),
            deadline: Date().addingTimeInterval(60 * 60 * 24 * 7),
            participants: [base.user.id],
            status: .active,
            proofImage: nil,
            proofSubmissionUserID: nil,
            votingFailureReason: nil
        )

        return MockSeed(
            user: base.user,
            group: base.group,
            challenges: [challenge],
            transactions: base.transactions,
            votes: base.votes,
            withdrawalRequests: base.withdrawalRequests
        )
    }()

    static let voting: MockSeed = {
        let base = MockSeed.activeChallenge
        guard var challenge = base.challenges.first else { return base }

        challenge.status = .voting
        challenge.proofImage = "mock_proof_base64"

        return MockSeed(
            user: base.user,
            group: base.group,
            challenges: [challenge],
            transactions: base.transactions,
            votes: base.votes,
            withdrawalRequests: base.withdrawalRequests
        )
    }()
}
