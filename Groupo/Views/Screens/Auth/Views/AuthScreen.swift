import SwiftUI

struct AuthScreen: View {
    @StateObject private var viewModel: AuthViewModel
    @EnvironmentObject var sessionManager: SessionManager

    init(authUseCase: AuthUseCaseProtocol, verifyOTPUseCase: VerifyOTPUseCaseProtocol) {
        _viewModel = StateObject(wrappedValue: AuthViewModel(authUseCase: authUseCase, verifyOTPUseCase: verifyOTPUseCase))
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
    return AuthScreen(
        authUseCase: AuthUseCase(userService: container.userService),
        verifyOTPUseCase: VerifyOTPUseCase(userService: container.userService)
    )
    .environmentObject(SessionManager(userDefaults: .standard))
}
