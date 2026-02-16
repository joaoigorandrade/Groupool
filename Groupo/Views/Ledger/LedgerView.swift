import SwiftUI

struct LedgerView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("Ledger Item 1")
                Text("Ledger Item 2")
            }
            .navigationTitle("Ledger")
        }
    }
}
