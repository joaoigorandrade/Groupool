import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @State private var viewModel: ProfileViewModel
    @State private var showLogoutConfirmation = false
    
    init(userService: any UserServiceProtocol) {
        _viewModel = State(wrappedValue: ProfileViewModel(userService: userService))
    }
    
    var body: some View {
        NavigationStack {
            List {
                profileHeaderSection
                statsSection
                settingsSection
                logoutSection
            }
            .navigationTitle("Profile")
            .alert("Log Out", isPresented: $showLogoutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) {
                    sessionManager.logout()
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
    }
}

// MARK: - Sections
private extension ProfileView {
    @ViewBuilder
    var profileHeaderSection: some View {
        Section {
            HStack(spacing: 16) {
                Image(systemName: viewModel.user.avatar)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .foregroundStyle(.gray.opacity(0.3))
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.user.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    statusBadge
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    @ViewBuilder
    var statusBadge: some View {
        Text(viewModel.statusText)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(viewModel.statusColor.opacity(0.2))
            .foregroundStyle(viewModel.statusColor)
            .clipShape(Capsule())
    }
    
    @ViewBuilder
    var statsSection: some View {
        Section("Stats") {
            HStack {
                Spacer()
                StatItem(value: "\(viewModel.user.challengesWon)", label: "Won", color: .green)
                Spacer()
                StatItem(value: "\(viewModel.user.challengesLost)", label: "Lost", color: .red)
                Spacer()
                StatItem(value: "\(Int(viewModel.reliabilityScore * 100))%", label: "Reliability", color: .blue)
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
    
    @ViewBuilder
    var settingsSection: some View {
        Section("Settings") {
            NavigationLink(destination: PIXKeysView()) {
                Label("PIX Keys", systemImage: "qrcode")
            }
            
            NavigationLink(destination: AppSettingsView()) {
                Label("App Settings", systemImage: "gear")
            }
        }
    }
    
    @ViewBuilder
    var logoutSection: some View {
        Section {
            Button(role: .destructive) {
                showLogoutConfirmation = true
            } label: {
                Label("Log Out", systemImage: "arrow.right.square")
            }
        }
    }
}

// MARK: - Subviews
private extension ProfileView {
    struct StatItem: View {
        let value: String
        let label: String
        let color: Color
        
        var body: some View {
            VStack {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
                
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview("Populated") {
    let services = AppServiceContainer.preview()
    ProfileView(userService: services.userService)
        .environmentObject(services)
}

#Preview("Dark Mode") {
    let services = AppServiceContainer.preview()
    ProfileView(userService: services.userService)
        .environmentObject(services)
        .preferredColorScheme(.dark)
}
