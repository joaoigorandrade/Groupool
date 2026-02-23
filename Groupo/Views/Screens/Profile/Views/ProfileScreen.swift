import SwiftUI

struct ProfileScreen: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @State private var viewModel: ProfileViewModel
    @State private var showLogoutConfirmation = false
    @Namespace private var namespace
    
    init(profileUseCase: ProfileUseCaseProtocol, pixUseCase: PIXUseCaseProtocol = PIXUseCase(userService: AppServiceContainer.preview().userService)) {
        _viewModel = State(wrappedValue: ProfileViewModel(profileUseCase: profileUseCase, pixUseCase: pixUseCase))
    }
    
    var body: some View {
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
    
    @ViewBuilder
    private var profileHeaderSection: some View {
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
    private var statusBadge: some View {
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
    private var statsSection: some View {
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
    private var settingsSection: some View {
        Section("Settings") {
            NavigationLink(destination: PIXKeysView(viewModel: viewModel)
                .navigationTransition(.zoom(sourceID: "pix-keys", in: namespace))
            ) {
                Label("PIX Keys", systemImage: "qrcode")
            }
            .matchedTransitionSource(id: "pix-keys", in: namespace)

            NavigationLink(destination: AppSettingsView()
                .navigationTransition(.zoom(sourceID: "app-settings", in: namespace))
            ) {
                Label("App Settings", systemImage: "gear")
            }
            .matchedTransitionSource(id: "app-settings", in: namespace)
        }
    }
    
    @ViewBuilder
    private var logoutSection: some View {
        Section {
            Button(role: .destructive) {
                showLogoutConfirmation = true
            } label: {
                Label("Log Out", systemImage: "arrow.right.square")
            }
        }
    }
    
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

#Preview {
    let services = AppServiceContainer.preview()
    return NavigationStack {
        ProfileScreen(
            profileUseCase: ProfileUseCase(userService: services.userService),
            pixUseCase: PIXUseCase(userService: services.userService)
        )
        .environmentObject(SessionManager(userDefaults: .standard))
    }
}
