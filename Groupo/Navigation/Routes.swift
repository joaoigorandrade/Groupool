import Foundation

enum MainTab: Hashable {
    case dashboard
    case create
    case treasury
}

enum DashboardRoute: Hashable {
    case profile
    case memberList
    case challengeVoting(Challenge)
}

enum TreasuryRoute: Hashable {
    case challengeVoting(Challenge)
    case withdrawalVoting(WithdrawalRequest)
    case monthHistory(TransactionSection)
}
