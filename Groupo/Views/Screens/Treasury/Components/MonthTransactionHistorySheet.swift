import SwiftUI

struct MonthTransactionHistorySheet: View {
    let section: TransactionSection
    @Namespace private var namespace

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(section.transactions) { transaction in
                    NavigationLink(destination: TransactionDetailView(transaction: transaction)
                        .navigationTransition(.zoom(sourceID: transaction.id, in: namespace))
                    ) {
                        TransactionDenseRow(transaction: transaction)
                    }
                    .matchedTransitionSource(id: transaction.id, in: namespace)
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
        .navigationTitle(section.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.appPrimaryBackground)
    }
}
