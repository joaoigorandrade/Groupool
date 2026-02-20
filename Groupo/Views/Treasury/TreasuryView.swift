//
//  TreasuryView.swift
//  Groupo
//
//  Created by Groupo on 2026-02-19.
//

import SwiftUI

struct TreasuryView: View {
    // MARK: - Dependencies
    @EnvironmentObject var services: AppServiceContainer
    @EnvironmentObject var coordinator: MainCoordinator
    
    // MARK: - State
    @StateObject private var ledgerViewModel: LedgerViewModel
    @StateObject private var governanceViewModel: GovernanceViewModel
    @State private var currentUser: User?
    
    // MARK: - Initialization
    init(
        transactionService: any TransactionServiceProtocol,
        challengeService: any ChallengeServiceProtocol,
        voteService: any VoteServiceProtocol,
        withdrawalService: any WithdrawalServiceProtocol,
        userService: any UserServiceProtocol,
        groupService: any GroupServiceProtocol
    ) {
        _ledgerViewModel = StateObject(wrappedValue: LedgerViewModel(transactionService: transactionService))
        _governanceViewModel = StateObject(wrappedValue: GovernanceViewModel(
            challengeService: challengeService,
            voteService: voteService,
            withdrawalService: withdrawalService,
            userService: userService,
            groupService: groupService
        ))
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            contentLayer
                .navigationTitle("Treasury")
                .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

// MARK: - Content Layer Extension
private extension TreasuryView {
    var contentLayer: some View {
        ScrollView {
            VStack(spacing: 12) {
                balanceStatsRow
                treasurySections
                Spacer()
            }
        }
        .refreshable {
            await refreshData()
        }
        .onReceive(services.userService.currentUser) { user in
            self.currentUser = user
        }
    }
    
    @ViewBuilder
    var treasurySections: some View {
        if governanceViewModel.activeItems.isEmpty && ledgerViewModel.sections.isEmpty && !ledgerViewModel.isLoading {
            emptyStateView
        } else {
            activeProposalsSection
            transactionList
        }
    }
}

// MARK: - Sections Extension
private extension TreasuryView {
    var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Treasury Activity", systemImage: "banknote")
        } description: {
            Text("Active proposals and transaction history will appear here.")
        } actions: {
            Button("Create New Proposal") {
                coordinator.presentCreateSheet()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.top, 40)
    }
    
    @ViewBuilder
    var activeProposalsSection: some View {
        HStack(spacing: 16) {
            if let firstItem = governanceViewModel.activeItems.first {
                proposalNavigationLink(for: firstItem)
                    .buttonStyle(PlainButtonStyle())
                    .frame(maxWidth: .infinity)
            }
            
            activityCalendarView
        }
        .padding(.horizontal)
    }
}

// MARK: - Subviews Extension
private extension TreasuryView {
    @ViewBuilder
    func proposalNavigationLink(for item: GovernanceItem) -> some View {
        switch item {
        case .challenge(let challenge):
            NavigationLink(destination: ChallengeVotingView(
                challenge: challenge,
                challengeService: services.challengeService,
                voteService: services.voteService,
                withdrawalService: services.withdrawalService,
                userService: services.userService,
                groupService: services.groupService
            )) {
                proposalCard(for: item)
            }
        case .withdrawal(let request):
            NavigationLink(destination: WithdrawalVotingView(
                withdrawal: request,
                challengeService: services.challengeService,
                voteService: services.voteService,
                withdrawalService: services.withdrawalService,
                userService: services.userService,
                groupService: services.groupService
            )) {
                proposalCard(for: item)
            }
        }
    }
    
    func proposalCard(for item: GovernanceItem) -> some View {
        ProposalCompactCard(
            item: item,
            time: governanceViewModel.timeRemaining(for: item.deadline),
            progress: governanceViewModel.progress(for: item),
            showVoteRequired: governanceViewModel.isEligibleToVote(on: item) && !governanceViewModel.hasVoted(on: item)
        )
    }
    
    @ViewBuilder
    var activityCalendarView: some View {
        if !ledgerViewModel.isLoading {
            TransactionCalendarView(
                summaries: ledgerViewModel.dailySummaries,
                size: governanceViewModel.activeItems.isEmpty ? .full : .half
            )
            .frame(maxWidth: .infinity)
        } else {
            SkeletonView()
                .frame(maxWidth: .infinity, minHeight: 160)
        }
    }
    
    var balanceStatsRow: some View {
        HStack(spacing: 16) {
            TreasuryStatCard(title: "Total Balance", value: currentUser?.currentEquity ?? 0)
            TreasuryStatCard(
                title: "Transactions",
                value: Decimal(ledgerViewModel.sections.flatMap { $0.transactions }.count),
                format: .number
            )
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    var transactionList: some View {
        if ledgerViewModel.isLoading {
            SkeletonView()
                .padding()
        } else if !ledgerViewModel.sections.isEmpty {
            LazyVStack {
                ForEach(ledgerViewModel.sections) { section in
                    transactionSection(section)
                }
            }
        } else {
            Text("No transactions yet.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding()
        }
    }
    
    func transactionSection(_ section: TransactionSection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(section.title)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 24)
            
            ZStack {
                ForEach(Array(section.transactions.prefix(4).enumerated()), id: \.element.id) { index, transaction in
                    NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                        TransactionDenseRow(transaction: transaction)
                    }
                    .offset(x: CGFloat(index) * 4, y: CGFloat(index) * 16)
                    .buttonStyle(PlainButtonStyle())
                    .zIndex(Double(section.transactions.count - index))
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Actions Extension
private extension TreasuryView {
    func refreshData() async {
        async let refreshLedger: () = ledgerViewModel.refresh()
        async let refreshGovernance: () = governanceViewModel.refresh()
        _ = await (refreshLedger, refreshGovernance)
    }
}

// MARK: - Preview Logic
#Preview("Populated") {
    let services = AppServiceContainer.preview()
    TreasuryView(
        transactionService: services.transactionService,
        challengeService: services.challengeService,
        voteService: services.voteService,
        withdrawalService: services.withdrawalService,
        userService: services.userService,
        groupService: services.groupService
    )
    .environmentObject(services)
}

#Preview("Dark Mode") {
    let services = AppServiceContainer.preview()
    TreasuryView(
        transactionService: services.transactionService,
        challengeService: services.challengeService,
        voteService: services.voteService,
        withdrawalService: services.withdrawalService,
        userService: services.userService,
        groupService: services.groupService
    )
    .environmentObject(services)
    .preferredColorScheme(.dark)
}
