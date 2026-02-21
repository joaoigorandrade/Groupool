
import SwiftUI

struct InviteLandingView: View {
    @EnvironmentObject private var container: AppServiceContainer
    @State private var viewModel = InviteLandingViewModel()
    
    var onJoin: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundView
                
                VStack(spacing: 24) {
                    headerView
                    detailsCard
                    contractSection
                    
                    Spacer()
                    
                    actionSection
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.load(container: container)
            }
        }
    }
}

// MARK: - Subviews
private extension InviteLandingView {
    var backgroundView: some View {
        Color("SecondaryBackground")
            .ignoresSafeArea()
    }
    
    var headerView: some View {
        Text(viewModel.groupName)
            .font(.titleLarge)
            .multilineTextAlignment(.center)
            .padding(.top, 40)
    }
    
    var detailsCard: some View {
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
    
    var contractSection: some View {
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
    var actionSection: some View {
        if viewModel.isLoading {
            ProgressView()
                .padding(.bottom, 20)
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
    
    struct DetailRow: View {
        let label: String
        let value: String
        var valueColor: Color = .primary
        
        var body: some View {
            HStack {
                Text(label)
                    .font(.captionText)
                    .foregroundColor(.secondary)
                Spacer()
                Text(value)
                    .font(.headlineText)
                    .foregroundColor(valueColor)
            }
        }
    }
    
    struct RuleRow: View {
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
}

#Preview("Standard") {
    InviteLandingView(onJoin: {})
        .environmentObject(AppServiceContainer.preview(seed: .pendingInvite))
}

#Preview("Loading") {
    let container = AppServiceContainer.preview(seed: .pendingInvite)
    return InviteLandingView(onJoin: {})
        .environmentObject(container)
}
