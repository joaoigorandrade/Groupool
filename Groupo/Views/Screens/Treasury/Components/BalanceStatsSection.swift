import SwiftUI

struct BalanceStatsSection: View {
    let viewModel: TreasuryViewModel

    var body: some View {
        HStack(spacing: 16) {
            TreasuryStatCard(title: "Total Balance", value: viewModel.currentUser?.currentEquity ?? 0)
            TreasuryStatCard(
                title: "Transactions",
                value: Decimal(viewModel.sections.flatMap { $0.transactions }.count),
                format: .number
            )
        }
        .padding(.horizontal)
    }
}
