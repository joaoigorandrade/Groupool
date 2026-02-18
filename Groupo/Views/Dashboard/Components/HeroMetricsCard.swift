import SwiftUI

struct HeroMetricsCard<Destination: View>: View {
    let totalPool: Decimal
    let personalStake: Decimal
    let availableStake: Decimal
    let frozenStake: Decimal
    let members: [User]
    let membersDestination: Destination
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TOTAL POOL")
                        .font(.caption2)
                        .fontWeight(.bold)
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
            
            Rectangle()
                .foregroundStyle(.primaryBackground)
                .frame(width: 1)
                .padding(.vertical, 4)
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("YOUR STAKE")
                        .font(.caption2)
                        .fontWeight(.bold)
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
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.15), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.15), radius: 25, x: 0, y: 10)
    }
    
    private var memberStackView: some View {
        NavigationLink(destination: membersDestination) {
            HStack(spacing: 8) {
                ZStack {
                    ForEach(Array(members.prefix(3).enumerated()), id: \.element.id) { index, member in
                        memberAvatar(for: member)
                            .offset(x: CGFloat(index - 1) * 20)
                            .zIndex(Double(3 - index))
                    }
                    
                    if members.count > 3 {
                        overflowIndicator
                            .offset(x: CGFloat(3 * 20))
                            .zIndex(0)
                    }
                }
                .frame(width: CGFloat((min(members.count, 3) + (members.count > 3 ? 1 : 0)) * 20) + 12, height: 32)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
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
            .font(.caption2)
            .fontWeight(.bold)
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
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .monospacedDigit()
        }
    }
}

//#Preview {
//    HeroMetricsCard(
//        totalPool: 12500,
//        personalStake: 500,
//        availableStake: 300,
//        frozenStake: 200,
//        members: [
//            User(id: "1", name: "Alice", phone: "+1234567890", avatar: "person.fill", joinedDate: Date(), role: .admin, status: .active, currentEquity: 1000, totalContributed: 1000, challengesParticipated: 5, challengesWon: 2, reputationScore: 100),
//            User(id: "2", name: "Bob", phone: "+1234567891", avatar: "person.fill", joinedDate: Date(), role: .member, status: .active, currentEquity: 800, totalContributed: 800, challengesParticipated: 4, challengesWon: 1, reputationScore: 90),
//            User(id: "3", name: "Charlie", phone: "+1234567892", avatar: "person.fill", joinedDate: Date(), role: .member, status: .inactive, currentEquity: 0, totalContributed: 500, challengesParticipated: 2, challengesWon: 0, reputationScore: 50),
//            User(id: "4", name: "David", phone: "+1234567893", avatar: "person.fill", joinedDate: Date(), role: .member, status: .active, currentEquity: 500, totalContributed: 500, challengesParticipated: 1, challengesWon: 0, reputationScore: 60)
//        ],
//        membersDestination: EmptyView()
//    )
//    .padding()
//    .background(Color("PrimaryBackground"))
//}
