import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var services: AppServiceContainer
    @StateObject private var viewModel: DashboardViewModel

    init(
        groupService: any GroupServiceProtocol,
        userService: any UserServiceProtocol,
        challengeService: any ChallengeServiceProtocol
    ) {
        _viewModel = StateObject(wrappedValue: DashboardViewModel(
            groupService: groupService,
            userService: userService,
            challengeService: challengeService
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
        ActiveChallengeCard()
    }
    
    private var activitySection: some View {
        ActivityFeedView()
    }
}

#Preview("Populated") {
    let services = AppServiceContainer.preview()
    DashboardView(
        groupService: services.groupService,
        userService: services.userService,
        challengeService: services.challengeService
    )
        .environmentObject(services)
        .environmentObject(MainCoordinator())
}

#Preview("Empty") {
    let services = AppServiceContainer.preview()
    DashboardView(
        groupService: services.groupService,
        userService: services.userService,
        challengeService: services.challengeService
    )
        .environmentObject(services)
        .environmentObject(MainCoordinator())
}

#Preview("Dark Mode") {
    let services = AppServiceContainer.preview()
    DashboardView(
        groupService: services.groupService,
        userService: services.userService,
        challengeService: services.challengeService
    )
        .environmentObject(services)
        .environmentObject(MainCoordinator())
        .preferredColorScheme(.dark)
}
