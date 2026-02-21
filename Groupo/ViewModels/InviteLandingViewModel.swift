import Foundation
import Observation
import Combine

@Observable
final class InviteLandingViewModel {
    private(set) var groupName: String = ""
    private(set) var inviterName: String = ""
    private(set) var buyInAmount: Decimal = 0
    private(set) var rules: [String] = [
        "1. Os depósitos são finais e não reembolsáveis.",
        "2. A decisão da maioria é soberana em disputas.",
        "3. O administrador tem voto de minerva."
    ]
    var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    
    func load(container: AppServiceContainer) {
        container.groupService.currentGroup
            .receive(on: DispatchQueue.main)
            .sink { [weak self] group in
                self?.groupName = group.name
                if let inviter = group.members.first {
                    self?.inviterName = inviter.name
                }
            }
            .store(in: &cancellables)
        
        container.challengeService.challenges
            .receive(on: DispatchQueue.main)
            .sink { [weak self] challenges in
                if let challenge = challenges.first(where: { $0.status == .active }) {
                    self?.buyInAmount = challenge.buyIn
                } else {
                    self?.buyInAmount = 500.00
                }
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    func connectAndDeposit(onJoin: @escaping () -> Void) async {
        isLoading = true
        
        // Simulate network delay
        try? await Task.sleep(for: .seconds(1.5))
        
        isLoading = false
        onJoin()
    }
}
