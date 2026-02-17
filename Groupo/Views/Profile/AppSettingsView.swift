import SwiftUI

struct AppSettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("selectedAppearance") private var selectedAppearance = "System"
    @AppStorage("selectedLanguage") private var selectedLanguage = "en"
    
    let appearances = ["System", "Light", "Dark"]
    let languages = [("English", "en"), ("Português (Brasil)", "pt-BR")]
    
    var body: some View {
        Form {
            Section("General") {
                Toggle("Notifications", isOn: $notificationsEnabled)
                    .tint(.blue)
            }
            
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
                }
                
                NavigationLink("Privacy Policy") {
                    Text("Privacy Policy Placeholder")
                        .navigationTitle("Privacy Policy")
                }
            }
        }
        .navigationTitle("App Settings")
    }
}

#Preview {
    NavigationStack {
        AppSettingsView()
    }
}
