import SwiftUI

struct CustomSplitView: View {
    @Bindable var viewModel: CreateExpenseViewModel
    let members: [User]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                summaryHeader
                
                memberList
            }
            .navigationTitle("Custom Split")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Subviews
private extension CustomSplitView {
    var summaryHeader: some View {
        VStack(spacing: 8) {
            Text("Total Amount")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text(viewModel.amount.formatted(.currency(code: "BRL")))
                .font(.largeTitle)
                .fontWeight(.bold)
            
            HStack {
                Text("Remaining:")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                
                Text(viewModel.remainingAmount.formatted(.currency(code: "BRL")))
                    .font(.headline)
                    .foregroundStyle(abs(viewModel.remainingAmount) < 0.01 ? .green : .red)
            }
            .padding(.top, 4)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .secondarySystemBackground))
    }
    
    var memberList: some View {
        List {
            Section {
                ForEach(members) { member in
                    memberRow(for: member)
                }
            } header: {
                listHeader
            } footer: {
                listFooter
            }
        }
        .listStyle(.insetGrouped)
    }
    
    func memberRow(for member: User) -> some View {
        HStack {
            Image(systemName: member.avatar)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
                .foregroundStyle(.blue)
            
            Text(member.name)
                .font(.body)
            
            Spacer()
            
            TextField("0.00", value: binding(for: member.id), format: .currency(code: "BRL"))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 100)
                .padding(8)
                .background(Color(uiColor: .systemGray6))
                .cornerRadius(8)
        }
        .padding(.vertical, 4)
    }
    
    var listHeader: some View {
        HStack {
            Text("Members")
            Spacer()
            Button("Split Evenly") {
                withAnimation {
                    viewModel.distributeEvenly(members: members)
                }
            }
            .font(.caption)
            .buttonStyle(.bordered)
        }
    }
    
    @ViewBuilder
    var listFooter: some View {
        if let error = viewModel.errorMessage {
            Text(error)
                .foregroundStyle(.red)
        }
    }
    
    func binding(for userId: UUID) -> Binding<Double> {
        Binding(
            get: {
                viewModel.splitAmounts[userId] ?? 0.0
            },
            set: { newValue in
                viewModel.splitAmounts[userId] = newValue
            }
        )
    }
}

#Preview {
    let services = AppServiceContainer.preview()
    CustomSplitView(
        viewModel: CreateExpenseViewModel(
            transactionService: services.transactionService,
            groupService: services.groupService
        ),
        members: []
    )
}
