import SwiftUI

struct DashboardScreen: View {
    @Environment(\.services) private var services
    @Environment(MainCoordinator.self) private var coordinator
    @State private var viewModel: DashboardViewModel
    @State private var isVisible = false

    init(
        groupUseCase: DashboardGroupUseCaseProtocol,
        challengeUseCase: DashboardChallengeUseCaseProtocol,
        transactionUseCase: DashboardTransactionUseCaseProtocol,
        userUseCase: DashboardUserUseCaseProtocol
    ) {
        _viewModel = State(wrappedValue: DashboardViewModel(
            groupUseCase: groupUseCase,
            challengeUseCase: challengeUseCase,
            transactionUseCase: transactionUseCase,
            userUseCase: userUseCase
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("PrimaryBackground")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        heroMetricsCard
                            .offset(y: isVisible ? 0 : 30)
                            .opacity(isVisible ? 1 : 0)
                            .animation(.spring(duration: 0.5, bounce: 0.3).delay(0.05), value: isVisible)

                        activeChallengeCard
                            .offset(y: isVisible ? 0 : 30)
                            .opacity(isVisible ? 1 : 0)
                            .animation(.spring(duration: 0.5, bounce: 0.3).delay(0.15), value: isVisible)

                        activitySection
                            .offset(y: isVisible ? 0 : 30)
                            .opacity(isVisible ? 1 : 0)
                            .animation(.spring(duration: 0.5, bounce: 0.3).delay(0.25), value: isVisible)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(height: 20)
                    }
                }
                .refreshable {
                    await viewModel.refresh()
                }
                .scrollBounceBehavior(.basedOnSize)
                .onAppear {
                    isVisible = true
                }
            }
            .navigationTitle("Dashboard")
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar { toolbarContent }
            .alert(
                "Something went wrong",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            profileLink
        }
    }

    @ViewBuilder
    private var profileLink: some View {
        NavigationLink(destination: ProfileScreen(
            profileUseCase: ProfileUseCase(userService: services.userService)
        )) {
            if let user = viewModel.currentUser {
                Image(systemName: user.avatar)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .foregroundStyle(.primary)
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Sections

    private var heroMetricsCard: some View {
        HeroMetricsCard(
            totalPool: viewModel.totalPool,
            personalStake: viewModel.totalStake,
            availableStake: viewModel.availableStake,
            frozenStake: viewModel.frozenStake,
            members: viewModel.members,
            membersDestination: MemberListView(
                groupService: services.groupService,
                challengeService: services.challengeService
            )
        )
    }

    private var activeChallengeCard: some View {
        let treasuryVM = makeTreasuryViewModel()
        return ActiveChallengeCard(
            challenge: viewModel.activeChallenge,
            onCreateChallenge: {
                coordinator.presentSheet(.challenge)
            },
            challengeDestination: { challenge in
                ChallengeVotingView(challenge: challenge, viewModel: treasuryVM)
            }
        )
    }

    private var activitySection: some View {
        ActivityFeedView(
            transactions: viewModel.transactions,
            onViewAll: {
                coordinator.selectTab(.treasury)
            },
            onTransactionSelected: { _ in
                coordinator.selectTab(.treasury)
            }
        )
    }

    // MARK: - Helpers

    /// Builds a TreasuryViewModel from the current environment services.
    /// Scoped here so DashboardScreen no longer receives it as an external dependency.
    private func makeTreasuryViewModel() -> TreasuryViewModel {
        TreasuryViewModel(
            transactionUseCase: TreasuryTransactionUseCase(transactionService: services.transactionService),
            challengeUseCase: TreasuryChallengeUseCase(challengeService: services.challengeService),
            voteUseCase: TreasuryVoteUseCase(voteService: services.voteService),
            withdrawalUseCase: TreasuryWithdrawalUseCase(withdrawalService: services.withdrawalService),
            groupUseCase: TreasuryGroupUseCase(groupService: services.groupService),
            userUseCase: TreasuryUserUseCase(userService: services.userService)
        )
    }
}

#Preview {
    let services = AppServiceContainer.preview()

    DashboardScreen(
        groupUseCase: DashboardGroupUseCase(groupService: services.groupService),
        challengeUseCase: DashboardChallengeUseCase(challengeService: services.challengeService),
        transactionUseCase: DashboardTransactionUseCase(transactionService: services.transactionService),
        userUseCase: DashboardUserUseCase(userService: services.userService)
    )
    .environment(\.services, services)
    .environment(MainCoordinator())
}
