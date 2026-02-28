import SwiftUI

struct DashboardScreen: View {
    @Environment(\.services) private var services
    @Environment(Router.self) private var router
    @State private var viewModel: DashboardViewModel
    @State private var isVisible = false
    @Namespace private var namespace

    init(
        userService: any UserServiceProtocol,
        groupService: any GroupServiceProtocol,
        challengeService: any ChallengeServiceProtocol,
        transactionService: any TransactionServiceProtocol
    ) {
        _viewModel = State(wrappedValue: DashboardViewModel(
            userService: userService,
            groupService: groupService,
            challengeService: challengeService,
            transactionService: transactionService
        ))
    }

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.dashboardPath) {
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
            .navigationDestination(for: DashboardRoute.self) { route in
                destinationView(for: route)
            }
        }
    }

    // MARK: - Route Destination Resolution

    @ViewBuilder
    private func destinationView(for route: DashboardRoute) -> some View {
        switch route {
        case .profile:
            ProfileScreen(
                userService: services.userService,
                pixService: services.pixService
            )
            .navigationTransition(.zoom(sourceID: "profile", in: namespace))

        case .memberList:
            MemberListView(
                groupService: services.groupService,
                challengeService: services.challengeService
            )
            .navigationTransition(.zoom(sourceID: "members", in: namespace))

        case .challengeVoting(let challenge):
            ChallengeVotingView(
                challenge: challenge,
                viewModel: makeTreasuryViewModel()
            )
            .navigationTransition(.zoom(sourceID: challenge.id, in: namespace))
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
        Button {
            router.push(.profile)
        } label: {
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
        .matchedTransitionSource(id: "profile", in: namespace)
    }

    // MARK: - Sections

    private var heroMetricsCard: some View {
        HeroMetricsCard(
            totalPool: viewModel.totalPool,
            personalStake: viewModel.totalStake,
            availableStake: viewModel.availableStake,
            frozenStake: viewModel.frozenStake,
            members: viewModel.members,
            namespace: namespace
        )
    }

    private var activeChallengeCard: some View {
        ActiveChallengeCard(
            challenge: viewModel.activeChallenge,
            namespace: namespace
        )
    }

    private var activitySection: some View {
        ActivityFeedView(
            transactions: viewModel.transactions,
            onViewAll: {
                router.selectTab(.treasury)
            },
            onTransactionSelected: { _ in
                router.selectTab(.treasury)
            }
        )
    }

    // MARK: - Helpers

    private func makeTreasuryViewModel() -> TreasuryViewModel {
        TreasuryViewModel(
            transactionService: services.transactionService,
            challengeService: services.challengeService,
            voteService: services.voteService,
            withdrawalService: services.withdrawalService,
            groupService: services.groupService,
            userService: services.userService
        )
    }
}

#Preview {
    let services = AppServiceContainer.preview()

    DashboardScreen(
        userService: services.userService,
        groupService: services.groupService,
        challengeService: services.challengeService,
        transactionService: services.transactionService
    )
    .environment(\.services, services)
    .environment(Router())
}
