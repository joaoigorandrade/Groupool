import SwiftUI

struct CustomSplitView: View {
    @ObservedObject var viewModel: CreateExpenseViewModel
    let members: [User]
    @Environment(\.dismiss) var dismiss
    
    // Formatting numbers
    private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "BRL"
        return formatter
    }()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Summary Header
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
                
                List {
                    Section {
                        ForEach(members) { member in
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
                    } header: {
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
                    } footer: {
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundStyle(.red)
                        }
                    }
                }
                .listStyle(.insetGrouped)
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
    
    private func binding(for userId: UUID) -> Binding<Double> {
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
    CustomSplitView(
        viewModel: CreateExpenseViewModel(),
        members: []
    )
}
