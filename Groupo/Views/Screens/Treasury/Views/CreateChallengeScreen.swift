import SwiftUI

struct CreateChallengeScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var toastManager: ToastManager
    @State private var viewModel: CreateChallengeViewModel

    init(
        challengeService: any ChallengeServiceProtocol,
        userService: any UserServiceProtocol,
        groupService: any GroupServiceProtocol,
        createChallengeUseCase: CreateChallengeUseCaseProtocol
    ) {
        _viewModel = State(wrappedValue: CreateChallengeViewModel(
            challengeService: challengeService,
            userService: userService,
            groupService: groupService,
            createChallengeUseCase: createChallengeUseCase
        ))
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
            NavigationStack {
                CreateChallengeStep1View(viewModel: viewModel)
                    .navigationDestination(for: String.self) { _ in
                        CreateChallengeStep2View(viewModel: viewModel) {
                            handleSubmission()
                        }
                    }
            }
        }
    }

    private func handleSubmission() {
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

// MARK: - Step 1: Details

private struct CreateChallengeStep1View: View {
    @Bindable var viewModel: CreateChallengeViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ChallengeDetailsSection(viewModel: viewModel)
                ChallengeDateSection(viewModel: viewModel)

                nextButton
            }
            .padding()
        }
        .background(Color(uiColor: .systemBackground))
        .navigationTitle("Detalhes")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var nextButton: some View {
        NavigationLink(value: "step2") {
            Text("Próximo")
                .font(.headline)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.isStep1Valid ? Color.brandTeal : Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(14)
        }
        .disabled(!viewModel.isStep1Valid)
    }
}

// MARK: - Step 2: Stakes & Confirm

private struct CreateChallengeStep2View: View {
    @Bindable var viewModel: CreateChallengeViewModel
    let onSubmit: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                coolingOffWarning
                ChallengeBetsSection(viewModel: viewModel)

                PrimaryButton(
                    title: "Criar Desafio",
                    isLoading: viewModel.isLoading,
                    isDisabled: !viewModel.isValid || !viewModel.canCreateChallenge,
                    action: onSubmit
                )
            }
            .padding()
        }
        .background(Color(uiColor: .systemBackground))
        .navigationTitle("Apostas")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var coolingOffWarning: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "hourglass")
                .foregroundStyle(.orange)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Cooling-off Period")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text("By creating this, you are entering a cooling-off period of 48h for new challenges.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Form Sections

private struct ChallengeDetailsSection: View {
    @Bindable var viewModel: CreateChallengeViewModel

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
            
            validationModePicker
        }
    }

    private var validationModePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Modo de Validação")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            
            Picker("Modo de Validação", selection: $viewModel.validationMode) {
                Text("Comprovante + Votação").tag(Challenge.ValidationMode.proof)
                Text("Apenas Votação").tag(Challenge.ValidationMode.votingOnly)
            }
            .pickerStyle(.segmented)
        }
    }
}

private struct ChallengeBetsSection: View {
    @Bindable var viewModel: CreateChallengeViewModel

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

            balanceInfo
            prizePoolInfo
        }
    }

    private var balanceInfo: some View {
        HStack {
            Spacer()
            Text("Disponível: \(viewModel.availableBalance.formatted(.currency(code: "BRL")))")
                .font(.caption)
                .foregroundStyle(viewModel.buyInAmount > viewModel.availableBalance ? .red : .secondary)
        }
    }

    private var prizePoolInfo: some View {
        HStack {
            Text("Prêmio Estimado")
            Spacer()
            Text("R$ \(viewModel.projectedPrizePool.formatted(.number.precision(.fractionLength(2))))")
                .foregroundColor(.green)
                .fontWeight(.bold)
        }
    }
}

private struct ChallengeDateSection: View {
    @Bindable var viewModel: CreateChallengeViewModel

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
    let services = AppServiceContainer.preview()
    CreateChallengeScreen(
        challengeService: services.challengeService,
        userService: services.userService,
        groupService: services.groupService,
        createChallengeUseCase: CreateChallengeUseCase(challengeService: services.challengeService)
    )
    .environmentObject(ToastManager())
}

#Preview("Active Challenge") {
    let services = AppServiceContainer.preview()
    CreateChallengeScreen(
        challengeService: services.challengeService,
        userService: services.userService,
        groupService: services.groupService,
        createChallengeUseCase: CreateChallengeUseCase(challengeService: services.challengeService)
    )
    .environmentObject(ToastManager())
}
