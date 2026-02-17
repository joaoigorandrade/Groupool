import SwiftUI

struct CreateChallengeView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: CreateChallengeViewModel
    
    init(dataService: MockDataService) {
        _viewModel = StateObject(wrappedValue: CreateChallengeViewModel(dataService: dataService))
    }
    
    var body: some View {
        NavigationStack {
            if let activeChallenge = viewModel.activeChallenge {
                VStack(spacing: 24) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                        .padding(.top, 40)
                    
                    Text("Desafio em Andamento")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Apenas um desafio pode estar ativo por vez no grupo.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("AGORA:")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text(activeChallenge.title)
                                    .font(.headline)
                                Text(activeChallenge.status == .voting ? "Em Votação" : "Em Progresso")
                                    .font(.subheadline)
                                    .foregroundColor(activeChallenge.status == .voting ? .purple : .green)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)
                        
                        HStack {
                            Image(systemName: "timer")
                            Text("Termina \(viewModel.activeChallengeRemainingTime)")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    Spacer()
                }
            } else {
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
                            Spacer()
                            Text("Disponível: \(viewModel.availableBalance.formatted(.currency(code: "BRL")))")
                                .font(.caption)
                                .foregroundStyle(viewModel.buyInAmount > viewModel.availableBalance ? .red : .secondary)
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
                .disabled(!viewModel.isValid || !viewModel.canCreateChallenge)
            }
        }
    }
}

#Preview {
    CreateChallengeView(dataService: MockDataService())
}
