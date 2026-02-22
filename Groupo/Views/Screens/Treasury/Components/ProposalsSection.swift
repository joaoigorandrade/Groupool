import SwiftUI

struct ProposalsSection: View {
    let viewModel: TreasuryViewModel
    let services: AppServiceContainer

    var body: some View {
        HStack(spacing: 16) {
            if !viewModel.activeItems.isEmpty {
                ProposalsCarousel(
                    viewModel: viewModel,
                    services: services
                )
                .frame(maxWidth: .infinity)
            }

            ActivityCalendarLink(viewModel: viewModel)
        }
        .padding(.horizontal)
    }
}

struct ActivityCalendarLink: View {
    let viewModel: TreasuryViewModel

    var body: some View {
        view
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private var view: some View {
        if !viewModel.isLoading {
            TransactionCalendarView(
                summaries: viewModel.dailySummaries,
                isSmall: !viewModel.activeItems.isEmpty
            )
        } else {
            SkeletonView()
        }
    }
}
