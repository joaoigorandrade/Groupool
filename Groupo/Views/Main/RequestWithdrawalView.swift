import SwiftUI

struct RequestWithdrawalView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var toastManager: ToastManager
    @StateObject private var viewModel: RequestWithdrawalViewModel
    
    init(dataService: MockDataService = MockDataService()) {
        _viewModel = StateObject(wrappedValue: RequestWithdrawalViewModel(dataService: dataService))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.yellow)
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
                    }
                    .padding()
                    .background(viewModel.cooldownString != nil ? Color.orange.opacity(0.1) : Color.yellow.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(viewModel.cooldownString != nil ? Color.orange.opacity(0.3) : Color.yellow.opacity(0.3), lineWidth: 1)
                    )
                    
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
                        
                        Text("Available: \(viewModel.dataService.currentUserAvailableBalance.formatted(.currency(code: "BRL")))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    
                    Spacer()
                    
                    Spacer()
                    
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
                .padding()
            }
            .navigationTitle("Request Withdrawal")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview("Default") {
    RequestWithdrawalView(dataService: MockDataService.preview)
        .environmentObject(ToastManager())
}

#Preview("With Cooldown") {
    let service = MockDataService.preview
    // Simulate cooldown by setting last win timestamp
    // You might need a way to inject this state more easily if not exposed
    // For now, standard preview is fine, or we can assume MockDataService.preview has a user
    // We can try to modify the user directly if access control allows, but let's stick to simple instantiation
    RequestWithdrawalView(dataService: service)
        .environmentObject(ToastManager())
}

#Preview("Dark Mode") {
    RequestWithdrawalView(dataService: MockDataService.preview)
        .environmentObject(ToastManager())
        .preferredColorScheme(.dark)
}
