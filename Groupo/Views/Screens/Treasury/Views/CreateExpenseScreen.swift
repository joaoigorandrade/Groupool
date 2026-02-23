import SwiftUI

struct CreateExpenseScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.services) private var services
    @EnvironmentObject private var toastManager: ToastManager
    @State private var viewModel: CreateExpenseViewModel
    @Namespace private var namespace
    
    init(
        createExpenseUseCase: CreateExpenseUseCaseProtocol,
        groupService: any GroupServiceProtocol
    ) {
        _viewModel = State(wrappedValue: CreateExpenseViewModel(
            createExpenseUseCase: createExpenseUseCase,
            groupService: groupService
        ))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                headerSection

                formSection

                createButton
            }
            .padding()
        }
    }
}

// MARK: - Subviews
private extension CreateExpenseScreen {
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
        NavigationLink(destination: CustomSplitView(viewModel: viewModel, members: viewModel.currentGroupMembers)
            .navigationTransition(.zoom(sourceID: "custom-split", in: namespace))
        ) {
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
        .matchedTransitionSource(id: "custom-split", in: namespace)
        .foregroundColor(.primary)
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
    CreateExpenseScreen(
        createExpenseUseCase: CreateExpenseUseCase(transactionService: services.transactionService),
        groupService: services.groupService
    )
    .environment(\.services, services)
    .environmentObject(ToastManager())
}

#Preview {
    let services = AppServiceContainer.preview()
    CreateExpenseScreen(
        createExpenseUseCase: CreateExpenseUseCase(transactionService: services.transactionService),
        groupService: services.groupService
    )
    .environment(\.services, services)
    .preferredColorScheme(.dark)
}
