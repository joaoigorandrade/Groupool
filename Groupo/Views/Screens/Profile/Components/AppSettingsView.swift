import SwiftUI

struct AppSettingsView: View {
    @Environment(\.services) var services
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("selectedAppearance") private var selectedAppearance = "System"
    @AppStorage("selectedLanguage") private var selectedLanguage = "en"
    @State private var showingResetAlert = false
    @Namespace private var namespace
    
    private let appearances = ["System", "Light", "Dark"]
    private let languages = [("English", "en"), ("Português (Brasil)", "pt-BR")]
    
    var body: some View {
        Form {
            generalSection
            preferencesSection
            aboutSection
            developerSection
        }
        .navigationTitle("App Settings")
        .alert("Reset Data?", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                services.resetMockData()
            }
        } message: {
            Text("This will delete all current data and restore the initial mock state. This action cannot be undone.")
        }
    }
}

// MARK: - Sections
private extension AppSettingsView {
    @ViewBuilder
    var generalSection: some View {
        Section("General") {
            Toggle("Notifications", isOn: $notificationsEnabled)
                .tint(.blue)
        }
    }
    
    @ViewBuilder
    var preferencesSection: some View {
        Section("Preferences") {
            Picker("Appearance", selection: $selectedAppearance) {
                ForEach(appearances, id: \.self) { appearance in
                    Text(appearance).tag(appearance)
                }
            }
            
            Picker("Language", selection: $selectedLanguage) {
                ForEach(languages, id: \.1) { language in
                    Text(language.0).tag(language.1)
                }
            }
        }
    }
    
    @ViewBuilder
    var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0 (Build 1)")
                    .foregroundStyle(.secondary)
            }
            
            NavigationLink("Terms of Service") {
                Text("Terms of Service Placeholder")
                    .navigationTitle("Terms of Service")
                    .navigationTransition(.zoom(sourceID: "terms", in: namespace))
            }
            .matchedTransitionSource(id: "terms", in: namespace)

            NavigationLink("Privacy Policy") {
                Text("Privacy Policy Placeholder")
                    .navigationTitle("Privacy Policy")
                    .navigationTransition(.zoom(sourceID: "privacy", in: namespace))
            }
            .matchedTransitionSource(id: "privacy", in: namespace)
        }
    }
    
    @ViewBuilder
    var developerSection: some View {
        Section("Developer") {
            Button(role: .destructive) {
                showingResetAlert = true
            } label: {
                Text("Reset Mock Data")
            }
            
            NavigationLink("Onboarding (Preview)") {
                let previewServices = AppServiceContainer.preview(seed: .pendingInvite)
                OnboardingScreen(
                    onboardingUseCase: OnboardingUseCase(groupService: previewServices.groupService),
                    onJoin: { print("Joined!") }
                )
                .environment(\.services, previewServices)
                .navigationTransition(.zoom(sourceID: "onboarding-preview", in: namespace))
            }
            .matchedTransitionSource(id: "onboarding-preview", in: namespace)
        }
    }
}

#Preview("Light") {
    let services = AppServiceContainer.preview()
    NavigationStack {
        AppSettingsView()
            .environment(\.services, services)
    }
}

#Preview("Dark") {
    let services = AppServiceContainer.preview()
    NavigationStack {
        AppSettingsView()
            .environment(\.services, services)
            .preferredColorScheme(.dark)
    }
}
