import SwiftUI

struct OnboardingScreen: View {
    @State private var viewModel: OnboardingViewModel
    var onJoin: () -> Void
    
    init(onboardingUseCase: OnboardingUseCaseProtocol, onJoin: @escaping () -> Void) {
        _viewModel = State(wrappedValue: OnboardingViewModel(onboardingUseCase: onboardingUseCase))
        self.onJoin = onJoin
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("SecondaryBackground").ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text(viewModel.groupName)
                        .font(.titleLarge)
                        .multilineTextAlignment(.center)
                        .padding(.top, 40)
                    
                    detailsCard
                    contractSection
                    
                    Spacer()
                    
                    actionSection
                }
            }
            .navigationBarHidden(true)
            .task {
                await viewModel.load()
            }
        }
    }
    
    private var detailsCard: some View {
        CardContainer {
            VStack(spacing: 16) {
                DetailRow(label: "Convidado por", value: viewModel.inviterName)
                Divider()
                DetailRow(
                    label: "Buy-in",
                    value: viewModel.buyInAmount.formatted(.currency(code: "BRL")),
                    valueColor: .brandTeal
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var contractSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("O Contrato")
                .font(.headlineText)
                .padding(.leading, 8)
            
            LazyVStack(spacing: 12) {
                ForEach(viewModel.rules, id: \.self) { rule in
                    RuleRow(text: rule)
                }
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var actionSection: some View {
        if viewModel.isLoading {
            ProgressView().padding(.bottom, 20)
        } else {
            PrimaryButton(title: "Connect PIX & Deposit", icon: "arrow.right") {
                Task {
                    await viewModel.connectAndDeposit(onJoin: onJoin)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
}

private struct DetailRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Text(label).font(.captionText).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.headlineText).foregroundColor(valueColor)
        }
    }
}

private struct RuleRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.shield.fill")
                .foregroundColor(.brandTeal)
                .font(.system(size: 20))
            
            Text(text)
                .font(.subheadlineText)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding()
        .background(Color("PrimaryBackground"))
        .cornerRadius(12)
    }
}

#Preview {
    OnboardingScreen(onboardingUseCase: OnboardingUseCase(groupService: AppServiceContainer.preview().groupService), onJoin: {})
}
