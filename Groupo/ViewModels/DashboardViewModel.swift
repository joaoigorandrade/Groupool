
import Foundation
import Combine

class DashboardViewModel: ObservableObject {
    @Published var totalPool: Decimal = 0
    @Published var members: [User] = []
    
    @Published var isLoading: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private var dataService: MockDataService?
    
    init(service: MockDataService? = nil) {
        self.dataService = service
        setupSubscribers()
    }
    
    func setup(service: MockDataService) {
        self.dataService = service
        setupSubscribers()
    }
    
    @MainActor
    func refresh() async {
        isLoading = true
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // In a real app, this would re-fetch data. 
        // For now, we just ensure subscribers are active and maybe force an update if MockDataService supports it.
        // Since MockDataService is local, the data is already "up to date", but we simulate the UX.
        
        isLoading = false
    }
    
    private func setupSubscribers() {
        guard let dataService = dataService else { return }
        
        dataService.$currentGroup
            .map { $0.totalPool }
            .assign(to: \.totalPool, on: self)
            .store(in: &cancellables)
            
        dataService.$currentGroup
            .map { $0.members }
            .assign(to: \.members, on: self)
            .store(in: &cancellables)
    }
}
