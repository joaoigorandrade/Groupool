import Foundation
import Combine

class MemberListViewModel: ObservableObject {
    @Published var members: [User] = []
    @Published var filteredMembers: [User] = []
    @Published var selectedStatus: UserStatusFilter = .all
    @Published var isLoading: Bool = true
    
    private var cancellables = Set<AnyCancellable>()
    private let mockDataService: MockDataService
    
    enum UserStatusFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case active = "Active"
        case inactive = "Inactive"
        
        var id: String { self.rawValue }
    }
    
    init(mockDataService: MockDataService) {
        self.mockDataService = mockDataService
        // Simulate initial load
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run {
                addSubscribers()
                isLoading = false
            }
        }
    }
    
    private func addSubscribers() {
        mockDataService.$currentGroup
            .map { $0.members }
            .sink { [weak self] returnedMembers in
                self?.members = returnedMembers
                self?.filterMembers()
            }
            .store(in: &cancellables)
            
        $selectedStatus
            .sink { [weak self] _ in
                self?.filterMembers()
            }
            .store(in: &cancellables)
    }
    
    private func filterMembers() {
        switch selectedStatus {
        case .all:
            filteredMembers = members.sorted(by: { $0.currentEquity > $1.currentEquity })
        case .active:
            filteredMembers = members
                .filter { $0.status == .active }
                .sorted(by: { $0.currentEquity > $1.currentEquity })
        case .inactive:
            filteredMembers = members
                .filter { $0.status == .inactive || $0.status == .suspended }
                .sorted(by: { $0.currentEquity > $1.currentEquity })
        }
    }
    
    func isFrozen(member: User) -> Bool {
        let activeChallenges = mockDataService.challenges.filter {
            ($0.status == .active || $0.status == .voting) &&
            $0.participants.contains(member.id)
        }
        return !activeChallenges.isEmpty
    }
    
    func getFrozenAmount(for member: User) -> Decimal {
         let activeChallenges = mockDataService.challenges.filter {
            ($0.status == .active || $0.status == .voting) &&
            $0.participants.contains(member.id)
        }
        return activeChallenges.reduce(0) { $0 + $1.buyIn }
    }
}
