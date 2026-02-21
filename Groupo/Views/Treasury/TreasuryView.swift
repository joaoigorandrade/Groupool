//
//  TreasuryView.swift
//  Groupo
//
//  Created by Groupo on 2026-02-19.
//

import SwiftUI

struct TreasuryView: View {
    // MARK: - Dependencies
    @Environment(\.services) private var services
    @Environment(MainCoordinator.self) private var coordinator
    
    // MARK: - State
    @State private var ledgerViewModel: LedgerViewModel
    let governanceViewModel: GovernanceViewModel
    
    // MARK: - Initialization
    init(
        transactionService: any TransactionServiceProtocol,
        userService: any UserServiceProtocol,
        governanceViewModel: GovernanceViewModel
    ) {
        _ledgerViewModel = State(wrappedValue: LedgerViewModel(
            transactionService: transactionService,
            userService: userService
        ))
        self.governanceViewModel = governanceViewModel
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    BalanceStatsSection(
                        ledgerViewModel: ledgerViewModel
                    )
                    
                    if governanceViewModel.activeItems.isEmpty && ledgerViewModel.sections.isEmpty && !ledgerViewModel.isLoading {
                        EmptyStateView(coordinator: coordinator)
                    } else {
                        ProposalsSection(
                            governanceViewModel: governanceViewModel,
                            ledgerViewModel: ledgerViewModel,
                            services: services
                        )
                        
                        TransactionHistorySection(ledgerViewModel: ledgerViewModel)
                    }
                    
                    Spacer()
                }
            }
            .refreshable {
                await refreshData()
            }
            .navigationTitle("Treasury")
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    private func refreshData() async {
        async let refreshLedger: () = ledgerViewModel.refresh()
        async let refreshGovernance: () = governanceViewModel.refresh()
        _ = await (refreshLedger, refreshGovernance)
    }
}

// MARK: - Subviews

private extension TreasuryView {
    
    struct BalanceStatsSection: View {
        let ledgerViewModel: LedgerViewModel
        
        var body: some View {
            HStack(spacing: 16) {
                TreasuryStatCard(title: "Total Balance", value: ledgerViewModel.currentUser?.currentEquity ?? 0)
                TreasuryStatCard(
                    title: "Transactions",
                    value: Decimal(ledgerViewModel.sections.flatMap { $0.transactions }.count),
                    format: .number
                )
            }
            .padding(.horizontal)
        }
    }
    
    struct ProposalsSection: View {
        let governanceViewModel: GovernanceViewModel
        let ledgerViewModel: LedgerViewModel
        let services: AppServiceContainer
        
        var body: some View {
            HStack(spacing: 16) {
                if let firstItem = governanceViewModel.activeItems.first {
                    ProposalNavigationLink(
                        item: firstItem,
                        governanceViewModel: governanceViewModel,
                        services: services
                    )
                    .frame(maxWidth: .infinity)
                }
                
                ActivityCalendarLink(ledgerViewModel: ledgerViewModel, governanceViewModel: governanceViewModel)
            }
            .padding(.horizontal)
        }
    }
    
    struct TransactionHistorySection: View {
        let ledgerViewModel: LedgerViewModel
        
        var body: some View {
            if !ledgerViewModel.sections.isEmpty {
                LazyVStack(spacing: 16) {
                    ForEach(ledgerViewModel.sections) { section in
                        TransactionMonthSection(section: section)
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }
    
    struct TransactionMonthSection: View {
        let section: TransactionSection
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
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
                        .buttonStyle(PlainButtonStyle())
                        .offset(x: CGFloat(index) * 4, y: CGFloat(index) * 16)
                        .zIndex(Double(section.transactions.count - index))
                    }
                }
                .padding(.horizontal)
                .frame(minHeight: CGFloat(min(section.transactions.count, 4)) * 24)
            }
        }
    }
    
    struct ProposalNavigationLink: View {
        let item: GovernanceItem
        let governanceViewModel: GovernanceViewModel
        let services: AppServiceContainer
        
        var body: some View {
            view
            .buttonStyle(PlainButtonStyle())
        }
        
        @ViewBuilder
        private var view: some View {
            switch item {
            case .challenge(let challenge):
                NavigationLink(destination: ChallengeVotingView(
                    challenge: challenge,
                    viewModel: governanceViewModel
                )) {
                    proposalCard
                }
            case .withdrawal(let request):
                NavigationLink(destination: WithdrawalVotingView(
                    withdrawal: request,
                    viewModel: governanceViewModel
                )) {
                    proposalCard
                }
            }
        }
        
        private var proposalCard: some View {
            ProposalCompactCard(
                item: item,
                time: governanceViewModel.timeRemaining(for: item.deadline),
                progress: governanceViewModel.progress(for: item),
                showVoteRequired: governanceViewModel.isEligibleToVote(on: item) && !governanceViewModel.hasVoted(on: item)
            )
        }
    }
    
    struct ActivityCalendarLink: View {
        let ledgerViewModel: LedgerViewModel
        let governanceViewModel: GovernanceViewModel
        
        var body: some View {
            view
                .frame(maxWidth: .infinity)
        }
        
        @ViewBuilder
        private var view: some View {
            if !ledgerViewModel.isLoading {
                TransactionCalendarView(
                    summaries: ledgerViewModel.dailySummaries,
                    isSmall: !governanceViewModel.activeItems.isEmpty
                )
            } else {
                SkeletonView()
            }
        }
    }
    
    struct EmptyStateView: View {
        let coordinator: MainCoordinator
        
        var body: some View {
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
    }
}

// MARK: - Previews

#Preview("Populated") {
    let services = AppServiceContainer.preview()
    TreasuryView(
        transactionService: services.transactionService, userService: services.userService,
        governanceViewModel: GovernanceViewModel(
            challengeService: services.challengeService,
            voteService: services.voteService,
            withdrawalService: services.withdrawalService,
            userService: services.userService,
            groupService: services.groupService
        )
    )
    .environment(MainCoordinator())
}

#Preview("Dark Mode") {
    let services = AppServiceContainer.preview()
    TreasuryView(
        transactionService: services.transactionService,
        userService: services.userService,
        governanceViewModel: GovernanceViewModel(
            challengeService: services.challengeService,
            voteService: services.voteService,
            withdrawalService: services.withdrawalService,
            userService: services.userService,
            groupService: services.groupService
        )
    )
    .environment(MainCoordinator())
    .preferredColorScheme(.dark)
}
