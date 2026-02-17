import SwiftUI

struct TransactionDetailView: View {
    let transaction: Transaction
    @EnvironmentObject var mockDataService: MockDataService
    
    private var relatedChallenge: Challenge? {
        guard let challengeID = transaction.relatedChallengeID else { return nil }
        return mockDataService.challenges.first(where: { $0.id == challengeID })
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                headerSection
                
                Divider()
                
                // Info
                infoSection
                
                // Related Challenge
                if let challenge = relatedChallenge {
                    challengeSection(challenge: challenge)
                }
                
                // Split Details
                if let splitDetails = transaction.splitDetails {
                    splitSection(details: splitDetails)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Detalhes da Transação")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Subviews
private extension TransactionDetailView {
    var headerSection: some View {
        VStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .fill(transaction.type.iconColor().opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: transaction.type.iconName())
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundColor(transaction.type.iconColor())
            }
            .frame(maxWidth: .infinity)
            
            Text(transaction.description)
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
            
            Text(transaction.formattedAmount())
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(transaction.type.amountColor())
        }
        .padding(.vertical, 10)
    }
    
    var infoSection: some View {
        VStack(spacing: 16) {
            detailRow(title: "Data", value: transaction.timestamp.formatted(date: .long, time: .shortened))
            detailRow(title: "Tipo", value: transaction.type.rawValue.capitalized)
            detailRow(title: "ID", value: transaction.id.uuidString.prefix(8).uppercased())
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
    
    func challengeSection(challenge: Challenge) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Desafio Relacionado")
                .font(.headline)
            
            NavigationLink(destination: ChallengeDetailView(challenge: challenge)) {
                HStack(spacing: 16) {
                    Image(systemName: "trophy")
                        .font(.title2)
                        .foregroundColor(.orange)
                        .frame(width: 40, height: 40)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(challenge.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(challenge.status.rawValue.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding()
                .background(Color.gray.opacity(0.05)) // Use a subtle background
                .cornerRadius(12)
            }
        }
    }
    
    func splitSection(details: [String: Decimal]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Divisão")
                .font(.headline)
            
            VStack(spacing: 0) {
                ForEach(details.sorted(by: { $0.key < $1.key }), id: \.key) { name, amount in
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.gray)
                        Text(name)
                        Spacer()
                        Text(amount.formatted(.currency(code: "BRL")))
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    if name != details.sorted(by: { $0.key < $1.key }).last?.key {
                        Divider()
                            .padding(.leading, 50)
                    }
                }
            }
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
    }
}

#Preview {
    NavigationView {
        TransactionDetailView(transaction: Transaction(
            id: UUID(),
            description: "Jantar de Comemoração",
            amount: 200.00,
            type: .expense,
            timestamp: Date(),
            relatedChallengeID: nil,
            splitDetails: ["João Silva": 66.66, "Maria Oliveira": 66.67, "Carlos Pereira": 66.67]
        ))
        .environmentObject(MockDataService())
    }
}
