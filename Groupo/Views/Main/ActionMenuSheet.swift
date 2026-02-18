//
//  ActionMenuSheet.swift
//  Groupo
//
//  Created by Joao Igor on 17/02/26.
//

import SwiftUI

struct ActionMenuSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataService: MockDataService
    @Binding var destination: Destination
    
    enum Destination { case menu, expense, challenge, withdrawal }
    
    var body: some View {
        VStack(spacing: 0) {
            view
                .id(destination)
                .frame(maxWidth: .infinity)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                .padding(.bottom, 20)
        }
        .animation(.spring(response: 0.35), value: destination)
    }
    
    private var navigationTitle: String {
        switch destination {
        case .menu:       return "Actions"
        case .expense:    return "Split Expense"
        case .challenge:  return "Create Challenge"
        case .withdrawal: return "Request Withdrawal"
        }
    }
    
    private var menuContent: some View {
        VStack(spacing: 16) {
            MenuButtonLabel(title: "Split Expense", icon: "banknote")
                .onTapGesture {
                    HapticManager.impact(style: .medium)
                    withAnimation(.spring()) { destination = .expense }
                }
            MenuButtonLabel(title: "Create Challenge", icon: "trophy")
                .onTapGesture {
                    HapticManager.impact(style: .medium)
                    withAnimation(.spring()) { destination = .challenge }
                }
            MenuButtonLabel(title: "Request Withdrawal", icon: "arrow.down.circle")
                .onTapGesture {
                    HapticManager.impact(style: .medium)
                    withAnimation(.spring()) { destination = .withdrawal }
                }
        }
        .padding()
    }
    
    @ViewBuilder
    private var view: some View {
        switch destination {
        case .menu:
            menuContent
        case .expense:
            CreateExpenseView()
        case .challenge:
            CreateChallengeView(dataService: dataService)
        case .withdrawal:
            RequestWithdrawalView(dataService: dataService)
        }
    }
}

private struct MenuButtonLabel: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.headline)
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.subheadline)
                .opacity(0.5)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.brandTeal.opacity(0.1))
        .foregroundColor(.brandTeal)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.brandTeal.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    ActionMenuSheet(destination: .constant(.menu))
        .environmentObject(MockDataService.preview)
}
