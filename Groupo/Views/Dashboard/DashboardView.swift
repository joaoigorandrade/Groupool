import SwiftUI

struct DashboardView: View {
    @Environment(\.services) private var services
    @Environment(MainCoordinator.self) private var coordinator
    @State private var viewModel: DashboardViewModel
    let governanceViewModel: GovernanceViewModel

    init(
        groupService: any GroupServiceProtocol,
        userService: any UserServiceProtocol,
        challengeService: any ChallengeServiceProtocol,
        transactionService: any TransactionServiceProtocol,
        governanceViewModel: GovernanceViewModel
    ) {
        _viewModel = State(wrappedValue: DashboardViewModel(
            groupService: groupService,
            userService: userService,
            challengeService: challengeService,
            transactionService: transactionService
        ))
        self.governanceViewModel = governanceViewModel
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
        NavigationLink(destination: ProfileView(userService: services.userService)) {
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
            governanceViewModel: governanceViewModel
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

#Preview("Populated") {
    let services = AppServiceContainer.preview()
    DashboardView(
        groupService: services.groupService,
        userService: services.userService,
        challengeService: services.challengeService,
        transactionService: services.transactionService,
        governanceViewModel: GovernanceViewModel(
            challengeService: services.challengeService,
            voteService: services.voteService,
            withdrawalService: services.withdrawalService,
            userService: services.userService,
            groupService: services.groupService
        )
    )
        .environment(\.services, services)
        .environment(MainCoordinator())
}

#Preview("Empty") {
    let services = AppServiceContainer.preview()
    DashboardView(
        groupService: services.groupService,
        userService: services.userService,
        challengeService: services.challengeService,
        transactionService: services.transactionService,
        governanceViewModel: GovernanceViewModel(
            challengeService: services.challengeService,
            voteService: services.voteService,
            withdrawalService: services.withdrawalService,
            userService: services.userService,
            groupService: services.groupService
        )
    )
        .environment(\.services, services)
        .environment(MainCoordinator())
}

#Preview("Dark Mode") {
    let services = AppServiceContainer.preview()
    DashboardView(
        groupService: services.groupService,
        userService: services.userService,
        challengeService: services.challengeService,
        transactionService: services.transactionService,
        governanceViewModel: GovernanceViewModel(
            challengeService: services.challengeService,
            voteService: services.voteService,
            withdrawalService: services.withdrawalService,
            userService: services.userService,
            groupService: services.groupService
        )
    )
        .environment(\.services, services)
        .environment(MainCoordinator())
        .preferredColorScheme(.dark)
}
