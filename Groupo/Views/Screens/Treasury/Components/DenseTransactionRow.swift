import SwiftUI

struct DenseTransactionRow: View {
    let transaction: Transaction

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Circle()
                    .fill(categoryColor)
                    .frame(width: 6, height: 6)
                    .padding(.leading, 2)
                Text(transaction.description)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            HStack {
                Spacer(minLength: 0)
                Text(transaction.amount, format: .currency(code: "USD").presentation(.narrow))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(transaction.amount >= 0 ? Color.green : Color.primary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }

    private var categoryColor: Color {
        let hue = Double(abs(transaction.id.hashValue) % 360) / 360.0
        return Color(hue: hue, saturation: 0.6, brightness: 0.9)
    }
}
