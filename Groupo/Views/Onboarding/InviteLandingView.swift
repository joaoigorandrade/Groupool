
import SwiftUI

struct InviteLandingView: View {
    @EnvironmentObject var container: AppServiceContainer
    @StateObject private var viewModel = InviteLandingViewModel()
    
    var onJoin: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("SecondaryBackground")
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text(viewModel.groupName)
                        .font(.titleLarge)
                        .multilineTextAlignment(.center)
                        .padding(.top, 40)
                    
                    CardContainer {
                        VStack(spacing: 16) {
                            HStack {
                                Text("Convidado por")
                                    .font(.captionText)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(viewModel.inviterName)
                                    .font(.headlineText)
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Buy-in")
                                    .font(.captionText)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(viewModel.buyInAmount.formatted(.currency(code: "BRL")))
                                    .font(.headlineText)
                                    .foregroundColor(.brandTeal)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("O Contrato")
                            .font(.headlineText)
                            .padding(.leading, 8)
                        
                        ForEach(viewModel.rules, id: \.self) { rule in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.shield.fill")
                                    .foregroundColor(.brandTeal)
                                    .font(.system(size: 20))
                                Text(rule)
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
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
                            .padding(.bottom, 20)
                    } else {
                        PrimaryButton(title: "Connect PIX & Deposit", icon: "arrow.right") {
                            viewModel.connectAndDeposit(onJoin: onJoin)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.load(container: container)
            }
        }
    }
}

#Preview {
    InviteLandingView(onJoin: {})
        .environmentObject(AppServiceContainer.preview(seed: .pendingInvite))
}
