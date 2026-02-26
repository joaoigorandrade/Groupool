import SwiftUI

struct EmptyStateView: View {
    @Environment(Router.self) private var router

    var body: some View {
        ContentUnavailableView {
            Label("No Treasury Activity", systemImage: "banknote")
        } description: {
            Text("Active proposals and transaction history will appear here.")
        } actions: {
            Button("Create New Proposal") { router.presentSheet(.challenge) }
                .buttonStyle(.borderedProminent)
        }
        .padding(.top, 40)
    }
}
