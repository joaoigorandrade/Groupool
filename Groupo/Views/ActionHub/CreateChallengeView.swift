import SwiftUI

struct CreateChallengeView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var toastManager: ToastManager
    @StateObject private var viewModel: CreateChallengeViewModel

    init(dataService: MockDataService) {
        _viewModel = StateObject(wrappedValue: CreateChallengeViewModel(dataService: dataService))
    }

    var body: some View {
        view
        .interactiveDismissDisabled(viewModel.isLoading)
    }
    
    @ViewBuilder
    private var view: some View {
        if let activeChallenge = viewModel.activeChallenge {
            ActiveChallengeView(
                challenge: activeChallenge,
                remainingTime: viewModel.activeChallengeRemainingTime
            )
        } else {
            CreateChallengeFormView(viewModel: viewModel) {
                viewModel.createChallenge { success, errorMessage in
                    if success {
                        toastManager.show(style: .success, message: "Desafio criado com sucesso!")
                        dismiss()
                    } else if let errorMessage {
                        toastManager.show(style: .error, message: errorMessage)
                    }
                }
            }
        }
    }
}

// MARK: - Active Challenge

private struct ActiveChallengeView: View {
    let challenge: Challenge
    let remainingTime: String

    var body: some View {
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
                        Text(challenge.title)
                            .font(.headline)
                        Text(challenge.status == .voting ? "Em Votação" : "Em Progresso")
                            .font(.subheadline)
                            .foregroundColor(challenge.status == .voting ? .purple : .green)
                    }
                    Spacer()
                }
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(12)

                HStack {
                    Image(systemName: "timer")
                    Text("Termina \(remainingTime)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

// MARK: - Create Challenge Form

private struct CreateChallengeFormView: View {
    @ObservedObject var viewModel: CreateChallengeViewModel
    let onSubmit: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            ChallengeDetailsSection(viewModel: viewModel)
            ChallengeBetsSection(viewModel: viewModel)
            ChallengeDateSection(viewModel: viewModel)

            PrimaryButton(
                title: "Criar Desafio",
                isLoading: viewModel.isLoading,
                isDisabled: !viewModel.isValid || !viewModel.canCreateChallenge,
                action: onSubmit
            )
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
    }
}

// MARK: - Form Sections

private struct ChallengeDetailsSection: View {
    @ObservedObject var viewModel: CreateChallengeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Detalhes do Desafio")

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
    }
}

private struct ChallengeBetsSection: View {
    @ObservedObject var viewModel: CreateChallengeViewModel

    private var buyInBinding: Binding<Double> {
        Binding(
            get: { NSDecimalNumber(decimal: viewModel.buyInAmount).doubleValue },
            set: { viewModel.buyInAmount = Decimal($0) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Apostas")

            HStack(alignment: .top) {
                Text("Valor do Buy-in (R$)")
                    .padding(.top, 12)
                Spacer()
                InputField(
                    title: "",
                    placeholder: "0.00",
                    value: buyInBinding,
                    errorMessage: viewModel.amountError
                )
                .frame(width: 150)
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
    }
}

private struct ChallengeDateSection: View {
    @ObservedObject var viewModel: CreateChallengeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Prazo")

            VStack(alignment: .leading) {
                DatePicker(
                    "Data de Término",
                    selection: $viewModel.deadline,
                    displayedComponents: [.date, .hourAndMinute]
                )

                if let dateError = viewModel.dateError {
                    Text(dateError)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }
}

// MARK: - Helpers

private struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.leading, 4)
    }
}

// MARK: - Previews

#Preview("Default") {
    CreateChallengeView(dataService: MockDataService.preview)
        .environmentObject(ToastManager())
}

#Preview("Active Challenge") {
    let service = MockDataService.preview
    service.addChallenge(title: "Existing Challenge", description: "Test", buyIn: 10, deadline: Date().addingTimeInterval(3600))
    return CreateChallengeView(dataService: service)
        .environmentObject(ToastManager())
}
