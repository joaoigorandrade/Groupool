import SwiftUI

struct TransactionDetailView: View {
    let transaction: Transaction
    @EnvironmentObject var services: AppServiceContainer
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                
                Divider()
                
                infoSection
                
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

#Preview("Expense") {
    let services = AppServiceContainer.preview()
    NavigationStack {
        TransactionDetailView(transaction: Transaction(
            id: UUID(),
            description: "Jantar de Comemoração",
            amount: 200.00,
            type: .expense,
            timestamp: Date(),
            relatedChallengeID: nil,
            splitDetails: ["João Silva": 66.66, "Maria Oliveira": 66.67, "Carlos Pereira": 66.67]
        ))
        .environmentObject(services)
    }
}

#Preview("Win") {
    let services = AppServiceContainer.preview()
    NavigationStack {
        TransactionDetailView(transaction: Transaction(
            id: UUID(),
            description: "Winning Payout",
            amount: 50.00,
            type: .win,
            timestamp: Date(),
            relatedChallengeID: nil,
            splitDetails: nil
        ))
        .environmentObject(services)
    }
}

#Preview("Withdrawal") {
    let services = AppServiceContainer.preview()
    NavigationStack {
        TransactionDetailView(transaction: Transaction(
            id: UUID(),
            description: "Withdrawal",
            amount: 100.00,
            type: .withdrawal,
            timestamp: Date(),
            relatedChallengeID: nil,
            splitDetails: nil
        ))
        .environmentObject(services)
    }
}
