import SwiftUI

struct RequestWithdrawalView: View {
    @Environment(\.dismiss) private var dismiss
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
                                
                                Text("Requests above 50% of your equity trigger a 24h review period to prevent pump & dump behavior.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
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
                            .background(Color.secondaryBackground)
                            .cornerRadius(12)
                        
                        Text("Available: \(viewModel.dataService.currentUserAvailableBalance.formatted(.currency(code: "BRL")))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    
                    Spacer()
                    
                    Button {
                        viewModel.submit()
                        dismiss()
                    } label: {
                        if viewModel.isValid {
                            Text("Request Withdrawal")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.brandTeal)
                                .cornerRadius(12)
                        } else {
                            Text("Invalid Amount")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray)
                                .cornerRadius(12)
                        }
                    }
                    .disabled(!viewModel.isValid)
                }
                .padding()
            }
            .navigationTitle("Request Withdrawal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    RequestWithdrawalView()
        .environmentObject(MockDataService())
}
