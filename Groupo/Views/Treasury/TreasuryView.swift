import SwiftUI

struct TreasuryView: View {
    @Environment(\.services) private var services
    @Environment(MainCoordinator.self) private var coordinator

    @State private var ledgerViewModel: LedgerViewModel
    @State private var selectedSection: TransactionSection?
    let governanceViewModel: GovernanceViewModel

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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    BalanceStatsSection(ledgerViewModel: ledgerViewModel)

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
            .refreshable { await refreshData() }
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
                        proposalLink(for: item)
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
            .onDisappear { stopAutoSwitch() }
            .onChange(of: items) { _, newItems in
                if selection == nil || !newItems.contains(where: { $0.id == selection }) {
                    selection = newItems.first?.id
                }
                startAutoSwitch()
            }
        }

        @ViewBuilder
        private func proposalLink(for item: GovernanceItem) -> some View {
            let card = ProposalCompactCard(
                item: item,
                time: governanceViewModel.timeRemaining(for: item.deadline),
                progress: governanceViewModel.progress(for: item),
                showVoteRequired: governanceViewModel.isEligibleToVote(on: item) && !governanceViewModel.hasVoted(on: item)
            )

            switch item {
            case .challenge(let challenge):
                NavigationLink(destination: ChallengeVotingView(challenge: challenge, viewModel: governanceViewModel)) {
                    card
                }
                .buttonStyle(PlainButtonStyle())
            case .withdrawal(let request):
                NavigationLink(destination: WithdrawalVotingView(withdrawal: request, viewModel: governanceViewModel)) {
                    card
                }
                .buttonStyle(PlainButtonStyle())
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
                            guard let currentID = selection,
                                  let currentIndex = items.firstIndex(where: { $0.id == currentID }) else {
                                selection = items.first?.id
                                return
                            }
                            selection = items[(currentIndex + 1) % items.count].id
                        }
                    }
                }
            }
        }

        private func stopAutoSwitch() {
            timerTask?.cancel()
            timerTask = nil
        }

        private func scale(for proxy: GeometryProxy) -> CGFloat {
            let containerWidth = proxy.size.width
            guard containerWidth > 0 else { return 1.0 }
            let progress = abs(proxy.frame(in: .scrollView(axis: .horizontal)).minX) / containerWidth
            return 1.0 - (min(progress, 1.0) * 0.05)
        }

        private func opacity(for proxy: GeometryProxy) -> Double {
            let containerWidth = proxy.size.width
            guard containerWidth > 0 else { return 1.0 }
            let progress = abs(proxy.frame(in: .scrollView(axis: .horizontal)).minX) / containerWidth
            return 1.0 - (min(progress, 1.0) * 0.3)
        }
    }

    struct TransactionHistorySection: View {
        let ledgerViewModel: LedgerViewModel
        @Binding var selectedSection: TransactionSection?

        var body: some View {
            if !ledgerViewModel.sections.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("History")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .padding(.horizontal, 24)

                    TransactionCarousel(
                        sections: ledgerViewModel.sections,
                        selectedSection: $selectedSection
                    )
                }
            }
        }
    }

    struct TransactionCarousel: View {
        let sections: [TransactionSection]
        @Binding var selectedSection: TransactionSection?

        @State private var scrollID: UUID?

        var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: -20) {
                    ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                        TransactionColumnCard(section: section)
                            .containerRelativeFrame(.horizontal, count: 5, span: 2, spacing: 0)
                            .id(section.id)
                            .visualEffect { content, proxy in
                                content
                                    .scaleEffect(columnScale(for: proxy), anchor: .leading)
                                    .opacity(columnOpacity(for: proxy))
                            }
                            .zIndex(Double(sections.count - index))
                            .onTapGesture { selectedSection = section }
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .padding(.bottom, 12)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $scrollID)
            .scrollClipDisabled()
            .onAppear { scrollID = sections.first?.id }
        }

        private func columnScale(for proxy: GeometryProxy) -> CGFloat {
            let minX = proxy.frame(in: .scrollView(axis: .horizontal)).minX
            guard minX > 0 else { return 1.0 }
            return 1.0 - min(minX / proxy.size.width, 1.0) * 0.06
        }

        private func columnOpacity(for proxy: GeometryProxy) -> Double {
            let minX = proxy.frame(in: .scrollView(axis: .horizontal)).minX
            guard minX > 0 else { return 1.0 }
            return 1.0 - min(minX / proxy.size.width, 1.0) * 0.35
        }
    }

    struct TransactionColumnCard: View {
        let section: TransactionSection

        private let peekCount = 2
        private let frontRowHeight: CGFloat = 68
        private let peekOffset: CGFloat = 6

        @State private var currentIndex: Int = 0
        @State private var timerTask: Task<Void, Never>?

        private var transactions: [Transaction] { section.transactions }
        private var currentTransaction: Transaction? { transactions.isEmpty ? nil : transactions[currentIndex] }
        private var remainingCount: Int { max(transactions.count - 1, 0) }

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                columnHeader

                Divider().opacity(0.15)

                ZStack(alignment: .top) {
                    ForEach(0 ..< min(peekCount, remainingCount), id: \.self) { peekIndex in
                        ghostCard(at: peekIndex + 1)
                    }

                    if let tx = currentTransaction {
                        DenseTransactionRow(transaction: tx)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            ))
                            .id(tx.id)
                    }
                }
                .frame(
                    height: frontRowHeight + CGFloat(min(peekCount, remainingCount)) * peekOffset,
                    alignment: .top
                )
                .padding(.top, 8)
                .clipped()

                if remainingCount > 0 {
                    moreLabel
                }

                Spacer(minLength: 12)
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .background(Material.thin)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 4)
            .onAppear { startCycling() }
            .onDisappear { stopCycling() }
        }

        @ViewBuilder
        private func ghostCard(at depth: Int) -> some View {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.primary.opacity(0.04), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 2)
                .frame(height: frontRowHeight)
                .scaleEffect(x: 1 - CGFloat(depth) * 0.04, y: 1, anchor: .bottom)
                .opacity(1 - Double(depth) * 0.25)
                .offset(y: CGFloat(depth) * peekOffset)
                .zIndex(Double(-depth))
        }

        private var columnHeader: some View {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(section.title.components(separatedBy: " ").first ?? section.title)
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    Text(section.title.components(separatedBy: " ").dropFirst().joined(separator: " "))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                NetFlowBadge(transactions: section.transactions)
            }
            .padding(.bottom, 10)
        }

        private var moreLabel: some View {
            HStack(spacing: 4) {
                Image(systemName: "ellipsis").imageScale(.small)
                Text("+\(remainingCount) more")
            }
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.secondary.opacity(0.12), in: Capsule())
            .padding(.top, 10)
        }

        private func startCycling() {
            stopCycling()
            guard transactions.count > 1 else { return }
            timerTask = Task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    await MainActor.run {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            currentIndex = (currentIndex + 1) % transactions.count
                        }
                    }
                }
            }
        }

        private func stopCycling() {
            timerTask?.cancel()
            timerTask = nil
        }
    }

    struct NetFlowBadge: View {
        let transactions: [Transaction]

        private var net: Decimal { transactions.reduce(0) { $0 + $1.amount } }
        private var isPositive: Bool { net >= 0 }

        var body: some View {
            HStack(spacing: 3) {
                Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.left").imageScale(.small)
                Text(net, format: .currency(code: "USD").presentation(.narrow)).lineLimit(1)
            }
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(isPositive ? Color.green : Color.red)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background((isPositive ? Color.green : Color.red).opacity(0.12), in: Capsule())
        }
    }

    struct DenseTransactionRow: View {
        let transaction: Transaction

        var body: some View {
            VStack(spacing: 4) {
                HStack {
                    Circle()
                        .fill(categoryColor)
                        .frame(width: 6, height: 6)
                        .padding(.leading, 2)
                    Text(transaction.description)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
                HStack {
                    Spacer(minLength: 0)
                    Text(transaction.amount, format: .currency(code: "USD").presentation(.narrow))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(transaction.amount >= 0 ? Color.green : Color.primary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        }

        private var categoryColor: Color {
            let hue = Double(abs(transaction.id.hashValue) % 360) / 360.0
            return Color(hue: hue, saturation: 0.6, brightness: 0.9)
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
                        Button("Done") { dismiss() }
                    }
                }
                .background(Color.appPrimaryBackground)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
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
                Button("Create New Proposal") { coordinator.presentCreateSheet() }
                    .buttonStyle(.borderedProminent)
            }
            .padding(.top, 40)
        }
    }
}

#Preview("Populated") {
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
