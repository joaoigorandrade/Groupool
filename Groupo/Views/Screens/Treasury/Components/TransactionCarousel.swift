import SwiftUI

struct TransactionCarousel: View {
    @Environment(Router.self) private var router

    let sections: [TransactionSection]
    var namespace: Namespace.ID

    @State private var scrollID: String?
    @State private var timerTask: Task<Void, Never>?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: -20) {
                ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                    Button {
                        router.push(TreasuryRoute.monthHistory(section))
                    } label: {
                        TransactionColumnCard(section: section)
                    }
                    .matchedTransitionSource(id: section.id, in: namespace)
                    .buttonStyle(.plain)
                    .containerRelativeFrame(.horizontal, count: 5, span: 2, spacing: 0)
                    .id(section.id)
                    .visualEffect { content, proxy in
                        content
                            .scaleEffect(columnScale(for: proxy), anchor: .leading)
                            .opacity(columnOpacity(for: proxy))
                    }
                    .zIndex(Double(sections.count - index))
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
        .onAppear {
            if scrollID == nil {
                scrollID = sections.first?.id
            }
            startAutoSwitch()
        }
        .onDisappear {
            stopAutoSwitch()
        }
    }

    private func startAutoSwitch() {
        stopAutoSwitch()
        guard sections.count > 1 else { return }
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                await MainActor.run {
                    guard let currentID = scrollID,
                          let currentIndex = sections.firstIndex(where: { $0.id == currentID }) else {
                        scrollID = sections.first?.id
                        return
                    }

                    let nextIndex = (currentIndex + 1) % sections.count
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                        scrollID = sections[nextIndex].id
                    }
                }
            }
        }
    }

    private func stopAutoSwitch() {
        timerTask?.cancel()
        timerTask = nil
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

#Preview {
    struct PreviewWrapper: View {
        @Namespace var namespace
        var body: some View {
            NavigationStack {
                TransactionCarousel(
                    sections: [
                        TransactionSection(title: "Jan 2024", transactions: [Transaction.preview()]),
                        TransactionSection(title: "Dec 2023", transactions: [Transaction.preview(type: .expense)])
                    ],
                    namespace: namespace
                )
            }
            .environment(Router())
        }
    }
    return PreviewWrapper()
}
