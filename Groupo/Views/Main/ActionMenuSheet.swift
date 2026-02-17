import SwiftUI

struct ActionMenuSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()
                
                NavigationLink {
                    CreateExpenseView()
                } label: {
                    MenuButtonLabel(title: "Split Expense", icon: "banknote")
                }
                
                NavigationLink {
                    CreateChallengeView()
                } label: {
                    MenuButtonLabel(title: "Create Challenge", icon: "trophy")
                }
                
                NavigationLink {
                    WithdrawalView()
                } label: {
                    MenuButtonLabel(title: "Request Withdrawal", icon: "arrow.down.circle")
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.height(350), .medium])
        .presentationDragIndicator(.visible)
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
    ActionMenuSheet()
}
