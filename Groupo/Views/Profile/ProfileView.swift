import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    
    init(userService: any UserServiceProtocol) {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(userService: userService))
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Header Section
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: viewModel.user.avatar)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .foregroundStyle(.gray.opacity(0.3)) // Placeholder color
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(viewModel.user.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            HStack {
                                Text(viewModel.statusText)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(viewModel.statusColor.opacity(0.2))
                                    .foregroundStyle(viewModel.statusColor)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Stats Section
                Section("Stats") {
                    HStack {
                        Spacer()
                        VStack {
                            Text("\(viewModel.user.challengesWon)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(.green)
                            Text("Won")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack {
                            Text("\(viewModel.user.challengesLost)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(.red)
                            Text("Lost")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack {
                            Text("\(Int(viewModel.reliabilityScore * 100))%")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(.blue)
                            Text("Reliability")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                // Settings Section
                Section("Settings") {
                    NavigationLink(destination: PIXKeysView()) {
                        Label("PIX Keys", systemImage: "qrcode")
                    }
                    
                    NavigationLink(destination: AppSettingsView()) {
                        Label("App Settings", systemImage: "gear")
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        // Logout action (placeholder)
                    } label: {
                        Label("Log Out", systemImage: "arrow.right.square")
                    }
                }
            }
            .navigationTitle("Profile")
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
