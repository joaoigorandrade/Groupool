import SwiftUI

struct TreasuryScreen: View {
    @Environment(\.services) private var services
    @Environment(MainCoordinator.self) private var coordinator

    @State private var viewModel: TreasuryViewModel
    @Namespace private var namespace

    init(viewModel: TreasuryViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    init(
        transactionUseCase: TreasuryTransactionUseCaseProtocol,
        challengeUseCase: TreasuryChallengeUseCaseProtocol,
        voteUseCase: TreasuryVoteUseCaseProtocol,
        withdrawalUseCase: TreasuryWithdrawalUseCaseProtocol,
        groupUseCase: TreasuryGroupUseCaseProtocol,
        userUseCase: TreasuryUserUseCaseProtocol
    ) {
        _viewModel = State(wrappedValue: TreasuryViewModel(
            transactionUseCase: transactionUseCase,
            challengeUseCase: challengeUseCase,
            voteUseCase: voteUseCase,
            withdrawalUseCase: withdrawalUseCase,
            groupUseCase: groupUseCase,
            userUseCase: userUseCase
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    BalanceStatsSection(viewModel: viewModel)

                    if viewModel.activeItems.isEmpty && viewModel.sections.isEmpty && !viewModel.isLoading {
                        EmptyStateView(coordinator: coordinator)
                    } else {
                        ProposalsSection(
                            viewModel: viewModel,
                            services: services,
                            namespace: namespace
                        )
                        TransactionHistorySection(
                            viewModel: viewModel,
                            namespace: namespace
                        )
                    }

                    Spacer()
                }
            }
            .refreshable { await viewModel.refresh() }
            .navigationTitle("Treasury")
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

#Preview {
    let services = AppServiceContainer.preview()
    return TreasuryScreen(
        transactionUseCase: TreasuryTransactionUseCase(transactionService: services.transactionService),
        challengeUseCase: TreasuryChallengeUseCase(challengeService: services.challengeService),
        voteUseCase: TreasuryVoteUseCase(voteService: services.voteService),
        withdrawalUseCase: TreasuryWithdrawalUseCase(withdrawalService: services.withdrawalService),
        groupUseCase: TreasuryGroupUseCase(groupService: services.groupService),
        userUseCase: TreasuryUserUseCase(userService: services.userService)
    )
    .environment(MainCoordinator())
    .environment(\.services, services)
}
