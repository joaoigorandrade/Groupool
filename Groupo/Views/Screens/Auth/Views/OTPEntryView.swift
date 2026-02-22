import SwiftUI

struct OTPEntryView: View {
    @Bindable var viewModel: AuthViewModel
    @EnvironmentObject var sessionManager: SessionManager
    @FocusState var focus: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Button(action: { viewModel.currentStep = .phoneEntry }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary)
                }
                Spacer()
            }
            .padding(.top)
            
            Spacer()
            
            headerSection
            
            otpInputSection
            
            errorSection
            
            Spacer()
            
            verifyButton
            
            resendSection
        }
        .padding()
        .onAppear {
            focus = true
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Enter Verification Code")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Sent to \(viewModel.maskedPhoneNumber)")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 20)
    }
    
    private var otpInputSection: some View {
        ZStack {
            TextField("", text: $viewModel.otpCode)
                .keyboardType(.numberPad)
                .focused($focus)
                .textContentType(.oneTimeCode)
                .accentColor(.clear)
                .foregroundColor(.clear)
            
            HStack(spacing: 12) {
                ForEach(0..<6, id: \.self) { index in
                    OTPDigitBox(index: index, code: viewModel.otpCode)
                        .onTapGesture {
                            focus = true
                        }
                }
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var errorSection: some View {
        if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .foregroundColor(.red)
                .font(.caption2)
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
    
    private var verifyButton: some View {
        PrimaryButton(
            title: "Verify",
            isLoading: viewModel.isLoading,
            isDisabled: viewModel.otpCode.count != 6
        ) {
            viewModel.verifyCode(sessionManager: sessionManager)
        }
        .padding(.horizontal)
    }
    
    private var resendSection: some View {
        Button(action: {
            viewModel.resendCode()
        }) {
            if viewModel.canResend {
                Text("Resend Code")
                    .foregroundColor(.blue)
                    .font(.subheadline.bold())
            } else {
                Text("Resend code in \(viewModel.timeRemaining)s")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
        }
        .disabled(!viewModel.canResend)
        .padding(.bottom, 20)
    }
}

struct OTPDigitBox: View {
    let index: Int
    let code: String
    
    var body: some View {
        let digit = (index < code.count) ? String(code[code.index(code.startIndex, offsetBy: index)]) : ""
        
        Text(digit)
            .font(.title)
            .fontWeight(.bold)
            .frame(width: 45, height: 55)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(digit.isEmpty ? Color.clear : Color.blue, lineWidth: 1.5)
            )
            .animation(.easeInOut(duration: 0.15), value: digit)
    }
}
