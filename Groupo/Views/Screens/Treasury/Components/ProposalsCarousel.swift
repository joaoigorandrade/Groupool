import SwiftUI

struct ProposalsCarousel: View {
    let viewModel: TreasuryViewModel
    let services: AppServiceContainer
    var namespace: Namespace.ID

    @State private var selection: UUID?
    @State private var timerTask: Task<Void, Never>?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                ForEach(viewModel.activeItems) { item in
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
            selection = viewModel.activeItems.first?.id
            startAutoSwitch()
        }
        .onDisappear { stopAutoSwitch() }
        .onChange(of: viewModel.activeItems) { _, newItems in
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
            time: viewModel.timeRemaining(for: item.deadline),
            progress: viewModel.progress(for: item),
            showVoteRequired: viewModel.isEligibleToVote(on: item) && !viewModel.hasVoted(on: item)
        )

        switch item {
        case .challenge(let challenge):
            NavigationLink(destination: ChallengeVotingView(challenge: challenge, viewModel: viewModel)
                .navigationTransition(.zoom(sourceID: challenge.id, in: namespace))
            ) {
                card
            }
            .matchedTransitionSource(id: challenge.id, in: namespace)
            .buttonStyle(PlainButtonStyle())
        case .withdrawal(let request):
            NavigationLink(destination: WithdrawalVotingView(withdrawal: request, viewModel: viewModel)
                .navigationTransition(.zoom(sourceID: request.id, in: namespace))
            ) {
                card
            }
            .matchedTransitionSource(id: request.id, in: namespace)
            .buttonStyle(PlainButtonStyle())
        }
    }

    private func startAutoSwitch() {
        stopAutoSwitch()
        guard viewModel.activeItems.count > 1 else { return }
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                await MainActor.run {
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                        guard let currentID = selection,
                              let currentIndex = viewModel.activeItems.firstIndex(where: { $0.id == currentID }) else {
                            selection = viewModel.activeItems.first?.id
                            return
                        }
                        selection = viewModel.activeItems[(currentIndex + 1) % viewModel.activeItems.count].id
                    }
                }
            }
        }
    }

    private func stopAutoSwitch() {
        timerTask?.cancel()
        timerTask = nil
    }

    nonisolated private func scale(for proxy: GeometryProxy) -> CGFloat {
        let containerWidth = proxy.size.width
        guard containerWidth > 0 else { return 1.0 }
        let progress = abs(proxy.frame(in: .scrollView(axis: .horizontal)).minX) / containerWidth
        return 1.0 - (min(progress, 1.0) * 0.05)
    }

    nonisolated private func opacity(for proxy: GeometryProxy) -> Double {
        let containerWidth = proxy.size.width
        guard containerWidth > 0 else { return 1.0 }
        let progress = abs(proxy.frame(in: .scrollView(axis: .horizontal)).minX) / containerWidth
        return 1.0 - (min(progress, 1.0) * 0.3)
    }
}
