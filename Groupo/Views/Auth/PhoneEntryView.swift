import SwiftUI
import Observation

struct PhoneEntryView: View {
    @State private var viewModel = PhoneEntryViewModel()
    @EnvironmentObject var sessionManager: SessionManager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                headerSection
                
                phoneInputSection
                
                Spacer()
                
                submitButton
            }
            .padding()
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $viewModel.navigateToOTP) {
                OTPEntryView(phoneNumber: viewModel.phoneNumber)
            }
        }
    }
}

// MARK: - Subviews
private extension PhoneEntryView {
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Enter your phone number")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("We will send you a verification code.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 20)
    }
    
    private var phoneInputSection: some View {
        HStack(spacing: 12) {
            countryCodeView
            phoneNumberField
        }
        .padding(.horizontal)
    }
    
    private var countryCodeView: some View {
        HStack {
            Text("🇧🇷")
            Text(viewModel.countryCode)
                .fontWeight(.medium)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var phoneNumberField: some View {
        @Bindable var viewModel = viewModel
        return TextField("11 99999-9999", text: $viewModel.phoneNumber)
            .keyboardType(.phonePad)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
    }
    
    private var submitButton: some View {
        PrimaryButton(
            title: "Send Code",
            isDisabled: !viewModel.isValid
        ) {
            viewModel.sendCode(sessionManager: sessionManager)
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
}

#Preview {
    PhoneEntryView()
}

