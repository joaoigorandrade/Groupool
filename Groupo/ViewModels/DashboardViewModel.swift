
import Combine
import Foundation

class DashboardViewModel: ObservableObject {
    @Published var totalPool: Decimal = 0
    @Published var members: [User] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()
    private let groupService: any GroupServiceProtocol

    init(groupService: any GroupServiceProtocol) {
        self.groupService = groupService
        setupSubscribers()
    }

    @MainActor
    func refresh() async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isLoading = false
    }

    private func setupSubscribers() {
        groupService.currentGroup
            .receive(on: DispatchQueue.main)
            .sink { [weak self] group in
                self?.totalPool = group.totalPool
                self?.members = group.members
            }
            .store(in: &cancellables)
    }
}
