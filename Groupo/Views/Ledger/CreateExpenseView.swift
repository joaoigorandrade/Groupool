import SwiftUI

struct CreateExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: MockDataService
    @EnvironmentObject var toastManager: ToastManager
    @StateObject private var viewModel = CreateExpenseViewModel()
    @State private var showCustomSplitSheet = false
    
    var body: some View {
        VStack(spacing: 24) {
            Text("New Expense")
                .font(.largeTitle)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top)
            
            VStack(spacing: 20) {
                InputField(
                    title: "Description",
                    placeholder: "e.g. Dinner, Groceries",
                    text: $viewModel.description,
                    errorMessage: viewModel.descriptionError,
                    characterLimit: 50,
                    showCharacterCount: true
                )
                
                InputField(
                    title: "Amount",
                    placeholder: "0.00",
                    value: $viewModel.amount,
                    errorMessage: viewModel.amountError,
                    keyboardType: .decimalPad
                )
                
                HStack {
                    Spacer()
                    Text("Available: \(dataService.currentUserAvailableBalance.formatted(.currency(code: "BRL")))")
                        .font(.caption)
                        .foregroundStyle(viewModel.amount > Double(truncating: dataService.currentUserAvailableBalance as NSNumber) ? .red : .secondary)
                }
                .padding(.top, -12)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Split")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("Split Option", selection: $viewModel.selectedSplit) {
                        ForEach(CreateExpenseViewModel.SplitOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: viewModel.selectedSplit) { _, newValue in
                        if newValue == .custom {
                            viewModel.initializeSplits(members: dataService.currentGroup.members)
                        }
                    }
                    
                    if viewModel.selectedSplit == .custom {
                        Button {
                            showCustomSplitSheet = true
                        } label: {
                            HStack {
                                Text("Configure Split")
                                Spacer()
                                if abs(viewModel.remainingAmount) < 0.01 {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                } else {
                                    Text("Remaining: \(viewModel.remainingAmount.formatted(.currency(code: "BRL")))")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color(uiColor: .secondarySystemBackground))
                            .cornerRadius(10)
                        }
                    }
                }
            }
            
            PrimaryButton(
                title: "Create Expense",
                icon: "checkmark.circle.fill",
                isLoading: viewModel.isLoading,
                isDisabled: !viewModel.isValid
            ) {
                 viewModel.createExpense(service: dataService) {
                     toastManager.show(style: .success, message: "Expense created successfully")
                     dismiss()
                 }
            }
        }
        .padding()
        .sheet(isPresented: $showCustomSplitSheet) {
            CustomSplitView(viewModel: viewModel, members: dataService.currentGroup.members)
        }
    }
}

#Preview("Default") {
    CreateExpenseView()
        .environmentObject(MockDataService.preview)
        .environmentObject(ToastManager())
}

#Preview("Dark Mode") {
    CreateExpenseView()
        .environmentObject(MockDataService.preview)
        .environmentObject(ToastManager())
        .preferredColorScheme(.dark)
}
