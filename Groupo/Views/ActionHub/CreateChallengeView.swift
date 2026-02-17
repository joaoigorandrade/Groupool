import SwiftUI

struct CreateChallengeView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var toastManager: ToastManager
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
                VStack(spacing: 0) {
                    Form {
                        Section(header: Text("Detalhes do Desafio")) {
                            InputField(
                                title: "Título",
                                placeholder: "Ex: Tênis no Domingo",
                                text: $viewModel.title,
                                errorMessage: viewModel.titleError,
                                characterLimit: 50,
                                showCharacterCount: true
                            )
                            
                            InputField(
                                title: "Descrição",
                                placeholder: "Regras, local, etc.",
                                text: $viewModel.description,
                                errorMessage: viewModel.descriptionError,
                                axis: .vertical,
                                characterLimit: 200,
                                showCharacterCount: true
                            )
                            .lineLimit(3...6)
                        }
                        
                        Section(header: Text("Apostas")) {
                            HStack(alignment: .top) {
                                Text("Valor do Buy-in (R$)")
                                    .padding(.top, 12)
                                Spacer()
                                VStack(alignment: .trailing) {
                                    InputField(
                                        title: "",
                                        placeholder: "0.00",
                                        value: Binding(
                                            get: { NSDecimalNumber(decimal: viewModel.buyInAmount).doubleValue },
                                            set: { viewModel.buyInAmount = Decimal($0) }
                                        ),
                                        errorMessage: viewModel.amountError
                                    )
                                    .frame(width: 150)
                                }
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
                            VStack(alignment: .leading) {
                                DatePicker("Data de Término", selection: $viewModel.deadline, displayedComponents: [.date, .hourAndMinute])
                                
                                if let dateError = viewModel.dateError {
                                    Text(dateError)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    
                    VStack {
                        PrimaryButton(
                            title: "Criar Desafio",
                            isLoading: viewModel.isLoading,
                            isDisabled: !viewModel.isValid || !viewModel.canCreateChallenge
                        ) {
                            viewModel.createChallenge { success, errorMsg in
                                if success {
                                    toastManager.show(style: .success, message: "Desafio criado com sucesso!")
                                    dismiss()
                                } else if let errorMsg = errorMsg {
                                    toastManager.show(style: .error, message: errorMsg)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .systemBackground))
                }
            }
        }
        .navigationTitle("Novo Desafio")
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(viewModel.isLoading)
    }
}

#Preview("Default") {
    CreateChallengeView(dataService: MockDataService.preview)
        .environmentObject(ToastManager())
}

#Preview("Active Challenge") {
    let service = MockDataService.preview
    // Simulate active challenge
    service.addChallenge(title: "Existing Challenge", description: "Test", buyIn: 10, deadline: Date().addingTimeInterval(3600))
    return CreateChallengeView(dataService: service)
        .environmentObject(ToastManager())
}
