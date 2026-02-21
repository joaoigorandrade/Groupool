//
//  ProposalCompactCard.swift
//  Groupo
//
//  Created by Groupo on 2026-02-19.
//

import SwiftUI

struct ProposalCompactCard: View {
    let item: GovernanceItem
    let time: String
    let progress: Double
    var showVoteRequired: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            Spacer()
            infoView
            ProgressView(value: progress)
                .tint(progressColor)
                .scaleEffect(x: 1, y: 0.5, anchor: .center)
            footerView
        }
        .treasuryCardStyle()
    }
}

private extension ProposalCompactCard {
    var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 24, height: 24)
                
                Image(systemName: iconName)
                    .font(.body)
                    .foregroundStyle(iconColor)
            }
        }
    }
    
    @ViewBuilder
    var infoView: some View {
        if case .challenge(let challenge) = item {
            HStack {
                Text("Stake")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text(challenge.buyIn, format: .currency(code: "BRL"))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .padding(.top, 4)
        } else if case .withdrawal(let request) = item {
            HStack {
                Text("Amount")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text(request.amount, format: .currency(code: "BRL"))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .padding(.top, 4)
        }
    }
    
    var footerView: some View {
        HStack {
            Spacer()
            if showVoteRequired {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                    Text("Action Required")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.1))
                .clipShape(Capsule())
            }
        }
    }
    
    var iconName: String {
        switch item {
        case .challenge: return "flag.fill"
        case .withdrawal: return "arrow.up.circle.fill"
        }
    }
    
    var iconColor: Color {
        switch item {
        case .challenge: return .orange
        case .withdrawal: return .blue
        }
    }
    
    var title: String {
        switch item {
        case .challenge(let challenge): return challenge.title
        case .withdrawal: return "Withdrawal Request"
        }
    }
    
    var progressColor: Color {
        if progress > 0.75 { return .red }
        if progress > 0.5 { return .orange }
        return .green
    }
}


#Preview {
    HStack(spacing: 20) {
        ProposalCompactCard(
            item: .challenge(.preview()),
            time: "2h 45m left",
            progress: 0.65,
            showVoteRequired: true
        )
        
        ProposalCompactCard(
            item: .withdrawal(.preview()),
            time: "1d 12h left",
            progress: 0.2
        )
    }
    .padding()
    .background(Color.appPrimaryBackground)
}
