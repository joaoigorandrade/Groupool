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
    @State private var selectedSection: TransactionSection?
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
                        
                        TransactionHistorySection(
                            ledgerViewModel: ledgerViewModel,
                            selectedSection: $selectedSection
                        )
                    }
                    
                    Spacer()
                }
            }
            .refreshable {
                await refreshData()
            }
            .navigationTitle("Treasury")
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(item: $selectedSection) { section in
                MonthTransactionHistorySheet(section: section)
            }
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
                if !governanceViewModel.activeItems.isEmpty {
                    ProposalsCarousel(
                        items: governanceViewModel.activeItems,
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
    
    struct ProposalsCarousel: View {
        let items: [GovernanceItem]
        let governanceViewModel: GovernanceViewModel
        let services: AppServiceContainer
        
        @State private var selection: UUID?
        @State private var timerTask: Task<Void, Never>?
        
        var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(items) { item in
                        ProposalNavigationLink(
                            item: item,
                            governanceViewModel: governanceViewModel,
                            services: services
                        )
                        .containerRelativeFrame(.horizontal)
                        .id(item.id)
                        .visualEffect { content, geometryProxy in
                            content
                                .scaleEffect(scale(for: geometryProxy))
                                .opacity(opacity(for: geometryProxy))
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $selection)
            .scrollTargetBehavior(.viewAligned)
            .scrollClipDisabled()
            .onAppear {
                selection = items.first?.id
                startAutoSwitch()
            }
            .onDisappear {
                stopAutoSwitch()
            }
            .onChange(of: items) { _, newItems in
                if selection == nil || !newItems.contains(where: { $0.id == selection }) {
                    selection = newItems.first?.id
                }
                startAutoSwitch()
            }
        }
        
        private func startAutoSwitch() {
            stopAutoSwitch()
            guard items.count > 1 else { return }
            
            timerTask = Task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    
                    await MainActor.run {
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                            switchToNext()
                        }
                    }
                }
            }
        }
        
        private func stopAutoSwitch() {
            timerTask?.cancel()
            timerTask = nil
        }
        
        private func switchToNext() {
            guard let currentID = selection,
                  let currentIndex = items.firstIndex(where: { $0.id == currentID }) else {
                selection = items.first?.id
                return
            }
            
            let nextIndex = (currentIndex + 1) % items.count
            selection = items[nextIndex].id
        }
        
        private func scale(for proxy: GeometryProxy) -> CGFloat {
            let containerWidth = proxy.size.width
            guard containerWidth > 0 else { return 1.0 }
            let minX = proxy.frame(in: .scrollView(axis: .horizontal)).minX
            let progress = abs(minX) / containerWidth
            return 1.0 - (min(progress, 1.0) * 0.05)
        }
        
        private func opacity(for proxy: GeometryProxy) -> Double {
            let containerWidth = proxy.size.width
            guard containerWidth > 0 else { return 1.0 }
            let minX = proxy.frame(in: .scrollView(axis: .horizontal)).minX
            let progress = abs(minX) / containerWidth
            return 1.0 - (min(progress, 1.0) * 0.3)
        }
    }


    
    struct TransactionHistorySection: View {
        let ledgerViewModel: LedgerViewModel
        @Binding var selectedSection: TransactionSection?
        
        var body: some View {
            if !ledgerViewModel.sections.isEmpty {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(ledgerViewModel.sections) { section in
                            Button {
                                selectedSection = section
                            } label: {
                                TransactionMonthSection(section: section)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 20)
            }
        }
    }
    
    struct TransactionMonthSection: View {
        let section: TransactionSection
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text(section.title)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .padding(.horizontal, 8)
                
                ZStack {
                    ForEach(Array(section.transactions.prefix(4).enumerated()), id: \.element.id) { index, transaction in
                        TransactionDenseRow(transaction: transaction)
                            .offset(x: CGFloat(index) * 4, y: CGFloat(index) * 12)
                            .zIndex(Double(section.transactions.count - index))
                    }
                }
                .padding(.trailing, 16)
                .frame(minHeight: CGFloat(min(section.transactions.count, 4)) * 24 + 40, alignment: .top)
            }
        }
    }
    
    struct MonthTransactionHistorySheet: View {
        let section: TransactionSection
        @Environment(\.dismiss) private var dismiss
        
        var body: some View {
            NavigationStack {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(section.transactions) { transaction in
                            NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                                TransactionDenseRow(transaction: transaction)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
                .navigationTitle(section.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
                .background(Color.appPrimaryBackground)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
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
