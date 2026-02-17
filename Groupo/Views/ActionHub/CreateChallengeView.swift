import SwiftUI

struct CreateChallengeView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: CreateChallengeViewModel
    
    init(dataService: MockDataService) {
        _viewModel = StateObject(wrappedValue: CreateChallengeViewModel(dataService: dataService))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Detalhes do Desafio")) {
                    TextField("Título", text: $viewModel.title)
                    TextField("Descrição", text: $viewModel.description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Apostas")) {
                    HStack {
                        Text("Valor do Buy-in (R$)")
                        Spacer()
                        TextField("0.00", value: $viewModel.buyInAmount, format: .number.precision(.fractionLength(2)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Prêmio Estimado")
                        Spacer()
                        Text("R$ \(viewModel.projectedPrizePool.formatted(.number.precision(.fractionLength(2))))")
                            .foregroundColor(.green)
                            .fontWeight(.bold)
                    }
                }
                
                Section(header: Text("Prazo")) {
                    DatePicker("Data de Término", selection: $viewModel.deadline, displayedComponents: [.date, .hourAndMinute])
                }
                
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Novo Desafio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Criar") {
                        viewModel.createChallenge { success in
                            if success {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.isValid)
                }
            }
        }
    }
}

#Preview {
    CreateChallengeView(dataService: MockDataService())
}
