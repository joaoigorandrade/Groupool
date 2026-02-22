import SwiftUI

struct TransactionHistorySection: View {
    let viewModel: TreasuryViewModel
    @Binding var selectedSection: TransactionSection?

    var body: some View {
        if !viewModel.sections.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("History")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .padding(.horizontal, 24)

                TransactionCarousel(
                    sections: viewModel.sections,
                    selectedSection: $selectedSection
                )
            }
        }
    }
}
