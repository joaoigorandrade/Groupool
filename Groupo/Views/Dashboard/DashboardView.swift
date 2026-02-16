import SwiftUI

struct DashboardView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Recent Activity") {
                    Text("Transaction 1")
                    Text("Transaction 2")
                }
            }
            .navigationTitle("Dashboard")
        }
    }
}
