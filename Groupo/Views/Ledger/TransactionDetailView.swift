import SwiftUI

struct TransactionDetailView: View {
    let transaction: Transaction
    @EnvironmentObject private var services: AppServiceContainer
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                
                Divider()
                
                infoSection
                
                splitSection
                
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
            transactionIcon
            
            Text(transaction.description)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(transaction.formattedAmount())
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(transaction.type.amountColor())
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
    }
    
    var transactionIcon: some View {
        ZStack {
            Circle()
                .fill(transaction.type.iconColor().opacity(0.1))
                .frame(width: 80, height: 80)
            
            Image(systemName: transaction.type.iconName())
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
                .foregroundColor(transaction.type.iconColor())
        }
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
    
    @ViewBuilder
    var splitSection: some View {
        if let details = transaction.splitDetails {
            VStack(alignment: .leading, spacing: 12) {
                Text("Divisão")
                    .font(.headline)
                
                VStack(spacing: 0) {
                    let sortedDetails = details.sorted(by: { $0.key < $1.key })
                    ForEach(sortedDetails, id: \.key) { name, amount in
                        splitRow(name: name, amount: amount, isLast: name == sortedDetails.last?.key)
                    }
                }
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
            }
        }
    }
    
    func splitRow(name: String, amount: Decimal, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.gray)
                Text(name)
                Spacer()
                Text(amount.formatted(.currency(code: "BRL")))
                    .foregroundColor(.secondary)
            }
            .padding()
            
            if !isLast {
                Divider()
                    .padding(.leading, 50)
            }
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
