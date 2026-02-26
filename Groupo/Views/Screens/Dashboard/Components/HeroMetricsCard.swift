
import SwiftUI

struct HeroMetricsCard: View {
    @Environment(Router.self) private var router

    let totalPool: Decimal
    let personalStake: Decimal
    let availableStake: Decimal
    let frozenStake: Decimal
    let members: [User]
    var namespace: Namespace.ID

    @State private var avatarsVisible = false

    var body: some View {
        HStack(spacing: 0) {
            poolAndMembersSection

            divider

            personalStakeSection
        }
        .dashboardCardStyle(backgroundColor: .clear)
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.4).delay(0.3)) {
                avatarsVisible = true
            }
        }
    }

    private var poolAndMembersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("TOTAL POOL")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .tracking(1.0)

                Text(totalPool.formatted(.currency(code: "BRL")))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }

            memberStackView
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.trailing, 8)
    }

    private var personalStakeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("YOUR STAKE")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .tracking(1.0)

                Text(personalStake.formatted(.currency(code: "BRL")))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }

            VStack(alignment: .leading, spacing: 4) {
                stakeDetailRow(
                    label: "Available",
                    amount: availableStake,
                    color: Color("AvailableGreen")
                )

                stakeDetailRow(
                    label: "Frozen",
                    amount: frozenStake,
                    color: Color("FrozenBlue")
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 16)
    }

    private var divider: some View {
        Rectangle()
            .foregroundStyle(.primary.opacity(0.1))
            .frame(width: 1)
            .padding(.vertical, 4)
    }

    private var memberStackView: some View {
        Button {
            router.push(.memberList)
        } label: {
            HStack(spacing: 8) {
                ZStack {
                    ForEach(Array(members.prefix(3).enumerated()), id: \.element.id) { index, member in
                        memberAvatar(for: member)
                            .offset(x: CGFloat(index) * 20)
                            .zIndex(Double(3 - index))
                            .scaleEffect(avatarsVisible ? 1 : 0.4)
                            .opacity(avatarsVisible ? 1 : 0)
                            .animation(.spring(duration: 0.4, bounce: 0.5).delay(Double(index) * 0.07), value: avatarsVisible)
                    }

                    if members.count > 3 {
                        overflowIndicator
                            .offset(x: CGFloat(3 * 20))
                            .zIndex(0)
                            .scaleEffect(avatarsVisible ? 1 : 0.4)
                            .opacity(avatarsVisible ? 1 : 0)
                            .animation(.spring(duration: 0.4, bounce: 0.5).delay(0.21), value: avatarsVisible)
                    }
                }
                .frame(width: CGFloat((min(members.count, 3) + (members.count > 3 ? 1 : 0)) * 20) + 12, height: 32)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .matchedTransitionSource(id: "members", in: namespace)
        .buttonStyle(.plain)
    }

    private func memberAvatar(for member: User) -> some View {
        ZStack {
            Image(systemName: member.avatar)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(member.status == .active ? .primary : .secondary)
                .frame(width: 32, height: 32)
                .background(Color("SecondaryBackground"))
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.3), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                .grayscale(member.status != .active ? 1.0 : 0.0)
                .overlay(alignment: .bottomTrailing) {
                    if member.status == .active {
                        Circle()
                            .fill(Color.green)
                            .stroke(Color("PrimaryBackground"), lineWidth: 2)
                            .frame(width: 6, height: 6)
                    }
                }
        }
    }

    private var overflowIndicator: some View {
        let remainingCount = members.count - 3

        return Text("+\(remainingCount)")
            .font(.caption2.weight(.bold))
            .foregroundStyle(.secondary)
            .frame(width: 32, height: 32)
            .background(Color("SecondaryBackground"))
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.3), lineWidth: 1)
            }
    }

    private func stakeDetailRow(label: String, amount: Decimal, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)

            Text(label + ":")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(amount.formatted(.currency(code: "BRL")))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.primary)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.4), value: amount)
        }
    }
}
