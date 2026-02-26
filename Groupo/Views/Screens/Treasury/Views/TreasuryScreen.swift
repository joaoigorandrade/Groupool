import SwiftUI

struct TreasuryScreen: View {
    @Environment(\.services) private var services
    @Environment(Router.self) private var router

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
        @Bindable var router = router
        NavigationStack(path: $router.treasuryPath) {
            ScrollView {
                VStack(spacing: 12) {
                    BalanceStatsSection(viewModel: viewModel)

                    if viewModel.activeItems.isEmpty && viewModel.sections.isEmpty && !viewModel.isLoading {
                        EmptyStateView()
                    } else {
                        ProposalsSection(
                            viewModel: viewModel,
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
            .navigationDestination(for: TreasuryRoute.self) { route in
                destinationView(for: route)
            }
        }
    }

    // MARK: - Route Destination Resolution

    @ViewBuilder
    private func destinationView(for route: TreasuryRoute) -> some View {
        switch route {
        case .challengeVoting(let challenge):
            ChallengeVotingView(challenge: challenge, viewModel: viewModel)
                .navigationTransition(.zoom(sourceID: challenge.id, in: namespace))

        case .withdrawalVoting(let withdrawal):
            WithdrawalVotingView(withdrawal: withdrawal, viewModel: viewModel)
                .navigationTransition(.zoom(sourceID: withdrawal.id, in: namespace))

        case .monthHistory(let section):
            MonthTransactionHistorySheet(section: section)
                .navigationTransition(.zoom(sourceID: section.id, in: namespace))
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
    .environment(Router())
    .environment(\.services, services)
}
