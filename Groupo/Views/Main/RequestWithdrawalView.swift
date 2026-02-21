import SwiftUI

struct RequestWithdrawalView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var toastManager: ToastManager
    @State private var viewModel: RequestWithdrawalViewModel
    
    init(
        withdrawalService: any WithdrawalServiceProtocol,
        userService: any UserServiceProtocol
    ) {
        _viewModel = State(wrappedValue: RequestWithdrawalViewModel(
            withdrawalService: withdrawalService,
            userService: userService
        ))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                cooldownWarningSection
                amountInputSection
                submitButton
            }
            .padding()
            .navigationTitle("Request Withdrawal")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Subviews
private extension RequestWithdrawalView {
    private var cooldownWarningSection: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(viewModel.cooldownString != nil ? .orange : .yellow)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Security Cooldown")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                if let cooldown = viewModel.cooldownString {
                    Text("Withdrawals locked for \(cooldown)")
                        .font(.title3)
                        .monospacedDigit()
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                } else {
                    Text("Requests above 50% of your equity trigger a 24h review period to prevent pump & dump behavior.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(viewModel.cooldownString != nil ? Color.orange.opacity(0.1) : Color.yellow.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(viewModel.cooldownString != nil ? Color.orange.opacity(0.3) : Color.yellow.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var amountInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Withdrawal Amount")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            TextField("R$ 0,00", value: $viewModel.amount, format: .currency(code: "BRL"))
                .font(.system(size: 40, weight: .bold))
                .multilineTextAlignment(.center)
                .keyboardType(.decimalPad)
                .padding()
                .background(Color.appSecondaryBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(viewModel.amountError != nil ? Color.red : Color.clear, lineWidth: 1)
                )
            
            if let error = viewModel.amountError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            Text("Available: \(viewModel.availableBalance.formatted(.currency(code: "BRL")))")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
    
    private var submitButton: some View {
        PrimaryButton(
            title: "Request Withdrawal",
            isLoading: viewModel.isLoading,
            isDisabled: !viewModel.isValid
        ) {
            viewModel.submit { success, errorMsg in
                if success {
                    toastManager.show(style: .success, message: "Withdrawal requested successfully")
                    dismiss()
                } else if let errorMsg = errorMsg {
                    toastManager.show(style: .error, message: errorMsg)
                }
            }
        }
    }
}

#Preview("Default") {
    let services = AppServiceContainer.preview()
    RequestWithdrawalView(
        withdrawalService: services.withdrawalService,
        userService: services.userService
    )
    .environmentObject(ToastManager())
}

#Preview("With Cooldown") {
    let services = AppServiceContainer.preview()
    RequestWithdrawalView(
        withdrawalService: services.withdrawalService,
        userService: services.userService
    )
    .environmentObject(ToastManager())
}

#Preview("Dark Mode") {
    let services = AppServiceContainer.preview()
    RequestWithdrawalView(
        withdrawalService: services.withdrawalService,
        userService: services.userService
    )
    .environmentObject(ToastManager())
    .preferredColorScheme(.dark)
}
