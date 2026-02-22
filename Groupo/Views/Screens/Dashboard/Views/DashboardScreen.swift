import SwiftUI

struct DashboardScreen: View {
    @Environment(\.services) private var services
    @Environment(MainCoordinator.self) private var coordinator
    @State private var viewModel: DashboardViewModel
    let treasuryViewModel: TreasuryViewModel

    init(
        groupUseCase: DashboardGroupUseCaseProtocol,
        challengeUseCase: DashboardChallengeUseCaseProtocol,
        transactionUseCase: DashboardTransactionUseCaseProtocol,
        userUseCase: DashboardUserUseCaseProtocol,
        treasuryViewModel: TreasuryViewModel
    ) {
        _viewModel = State(wrappedValue: DashboardViewModel(
            groupUseCase: groupUseCase,
            challengeUseCase: challengeUseCase,
            transactionUseCase: transactionUseCase,
            userUseCase: userUseCase
        ))
        self.treasuryViewModel = treasuryViewModel
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("PrimaryBackground")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        heroMetricsCard
                        activeChallengeCard
                        activitySection
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
            }
            .navigationTitle("Dashboard")
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar { toolbarContent }
        }
    }
    
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
        ActiveChallengeCard(
            challenge: viewModel.activeChallenge,
            onCreateChallenge: {
                coordinator.presentSheet(.challenge)
            },
            services: services,
            treasuryViewModel: treasuryViewModel
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
}

#Preview {
    let services = AppServiceContainer.preview()
    let treasuryVM = TreasuryViewModel(
        transactionUseCase: TreasuryTransactionUseCase(transactionService: services.transactionService),
        challengeUseCase: TreasuryChallengeUseCase(challengeService: services.challengeService),
        voteUseCase: TreasuryVoteUseCase(voteService: services.voteService),
        withdrawalUseCase: TreasuryWithdrawalUseCase(withdrawalService: services.withdrawalService),
        groupUseCase: TreasuryGroupUseCase(groupService: services.groupService),
        userUseCase: TreasuryUserUseCase(userService: services.userService)
    )
    
    DashboardScreen(
        groupUseCase: DashboardGroupUseCase(groupService: services.groupService),
        challengeUseCase: DashboardChallengeUseCase(challengeService: services.challengeService),
        transactionUseCase: DashboardTransactionUseCase(transactionService: services.transactionService),
        userUseCase: DashboardUserUseCase(userService: services.userService),
        treasuryViewModel: treasuryVM
    )
    .environment(\.services, services)
    .environment(MainCoordinator())
}
