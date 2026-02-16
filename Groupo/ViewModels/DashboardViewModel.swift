
import Foundation
import Combine

class DashboardViewModel: ObservableObject {
    @Published var totalPool: Decimal = 0
    @Published var members: [User] = []
    
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
