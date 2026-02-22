import SwiftUI

struct EmptyStateView: View {
    let coordinator: MainCoordinator

    var body: some View {
        ContentUnavailableView {
            Label("No Treasury Activity", systemImage: "banknote")
        } description: {
            Text("Active proposals and transaction history will appear here.")
        } actions: {
            Button("Create New Proposal") { coordinator.presentSheet(.challenge) }
                .buttonStyle(.borderedProminent)
        }
        .padding(.top, 40)
    }
}
