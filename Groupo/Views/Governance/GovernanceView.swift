import SwiftUI

struct GovernanceView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("Vote 1")
                Text("Vote 2")
            }
            .navigationTitle("Governance")
        }
    }
}
