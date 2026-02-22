import SwiftUI

struct TransactionCarousel: View {
    let sections: [TransactionSection]
    @Binding var selectedSection: TransactionSection?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(sections) { section in
                    TransactionSectionCard(section: section)
                        .onTapGesture {
                            selectedSection = section
                        }
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

private struct TransactionSectionCard: View {
    let section: TransactionSection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section.title)
                .font(.headline)
                .foregroundStyle(.primary)
            
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(section.transactions.count) Transactions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(width: 160)
        .background(Color("SecondaryBackground"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    TransactionCarousel(
        sections: [
            TransactionSection(title: "Jan 2024", transactions: []),
            TransactionSection(title: "Dec 2023", transactions: [])
        ],
        selectedSection: .constant(nil)
    )
}
