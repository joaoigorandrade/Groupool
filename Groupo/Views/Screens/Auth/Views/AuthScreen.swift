import SwiftUI

struct AuthScreen: View {
    @State private var viewModel: AuthViewModel
    @EnvironmentObject var sessionManager: SessionManager

    init(authService: any AuthServiceProtocol) {
        _viewModel = State(wrappedValue: AuthViewModel(authService: authService))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                switch viewModel.currentStep {
                case .phoneEntry:
                    PhoneEntryView(viewModel: viewModel)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                case .otpEntry:
                    OTPEntryView(viewModel: viewModel)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                }
            }
            .animation(.default, value: viewModel.currentStep)
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    let container = AppServiceContainer.preview()
    return AuthScreen(authService: container.authService)
        .environmentObject(SessionManager(userDefaults: .standard))
}
