import SwiftUI

struct CreateExpenseView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataService: MockDataService
    @StateObject private var viewModel = CreateExpenseViewModel()
    
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
                    text: $viewModel.description
                )
                
                InputField(
                    title: "Amount",
                    placeholder: "0.00",
                    value: $viewModel.amount,
                    errorMessage: viewModel.errorMessage
                )
                
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
                }
            }
            
            Spacer()
            
            PrimaryButton(
                title: "Create Expense",
                icon: "checkmark.circle.fill",
                isDisabled: !viewModel.isValid
            ) {
                if viewModel.validate(availableBalance: dataService.currentUserAvailableBalance) {
                    dataService.addExpense(
                        amount: Decimal(viewModel.amount),
                        description: viewModel.description
                    )
                    HapticManager.notification(type: .success)
                    presentationMode.wrappedValue.dismiss()
                } else {
                    HapticManager.notification(type: .error)
                }
            }
            .padding(.bottom)
        }
        .padding()
        .background(Color.primaryBackground.edgesIgnoringSafeArea(.all))
    }
}

#Preview {
    CreateExpenseView()
        .environmentObject(MockDataService())
}
