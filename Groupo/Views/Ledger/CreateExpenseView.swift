import SwiftUI

struct CreateExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var services: AppServiceContainer
    @EnvironmentObject private var toastManager: ToastManager
    @State private var viewModel: CreateExpenseViewModel
    @State private var showCustomSplitSheet = false
    
    init(
        transactionService: any TransactionServiceProtocol,
        groupService: any GroupServiceProtocol
    ) {
        _viewModel = State(wrappedValue: CreateExpenseViewModel(
            transactionService: transactionService,
            groupService: groupService
        ))
    }
    
    var body: some View {
        VStack(spacing: 24) {
            headerSection
            
            formSection
            
            createButton
        }
        .padding()
        .sheet(isPresented: $showCustomSplitSheet) {
            CustomSplitView(viewModel: viewModel, members: viewModel.currentGroupMembers)
        }
    }
}

// MARK: - Subviews
private extension CreateExpenseView {
    var headerSection: some View {
        Text("New Expense")
            .font(.largeTitle)
            .fontWeight(.bold)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top)
    }
    
    var formSection: some View {
        @Bindable var vm = viewModel
        
        return VStack(spacing: 20) {
            InputField(
                title: "Description",
                placeholder: "e.g. Dinner, Groceries",
                text: $vm.description,
                errorMessage: vm.descriptionError,
                characterLimit: 50,
                showCharacterCount: true
            )
            
            VStack(spacing: 8) {
                InputField(
                    title: "Amount",
                    placeholder: "0.00",
                    value: $vm.amount,
                    errorMessage: vm.amountError,
                    keyboardType: .decimalPad
                )
                
                HStack {
                    Spacer()
                    Text("Available: \(vm.currentGroupBalance.formatted(.currency(code: "BRL")))")
                        .font(.caption)
                        .foregroundStyle(vm.amount > Double(truncating: vm.currentGroupBalance as NSNumber) ? .red : .secondary)
                }
            }
            
            splitSection
        }
    }
    
    @ViewBuilder
    var splitSection: some View {
        @Bindable var vm = viewModel
        
        VStack(alignment: .leading, spacing: 12) {
            Text("Split")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Picker("Split Option", selection: $vm.selectedSplit) {
                ForEach(CreateExpenseViewModel.SplitOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: vm.selectedSplit) { _, newValue in
                if newValue == .custom {
                    vm.initializeSplits(members: vm.currentGroupMembers)
                }
            }
            
            if vm.selectedSplit == .custom {
                customSplitButton
            }
        }
    }
    
    var customSplitButton: some View {
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
    
    var createButton: some View {
        PrimaryButton(
            title: "Create Expense",
            icon: "checkmark.circle.fill",
            isLoading: viewModel.isLoading,
            isDisabled: !viewModel.isValid
        ) {
             viewModel.createExpense {
                 toastManager.show(style: .success, message: "Expense created successfully")
                 dismiss()
             }
        }
    }
}

#Preview("Default") {
    let services = AppServiceContainer.preview()
    CreateExpenseView(
        transactionService: services.transactionService,
        groupService: services.groupService
    )
    .environmentObject(services)
    .environmentObject(ToastManager())
}

#Preview("Dark Mode") {
    let services = AppServiceContainer.preview()
    CreateExpenseView(
        transactionService: services.transactionService,
        groupService: services.groupService
    )
    .environmentObject(services)
    .environmentObject(ToastManager())
    .preferredColorScheme(.dark)
}
