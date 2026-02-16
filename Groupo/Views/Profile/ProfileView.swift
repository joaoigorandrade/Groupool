import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("Settings")
                Text("Log Out")
            }
            .navigationTitle("Profile")
        }
    }
}
