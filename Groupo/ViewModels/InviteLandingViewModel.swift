
import Combine
import SwiftUI

class InviteLandingViewModel: ObservableObject {
    @Published private(set) var groupName: String = ""
    @Published private(set) var inviterName: String = ""
    @Published private(set) var buyInAmount: Decimal = 0
    @Published private(set) var rules: [String] = [
        "1. Os depósitos são finais e não reembolsáveis.",
        "2. A decisão da maioria é soberana em disputas.",
        "3. O administrador tem voto de minerva."
    ]
    @Published var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    
    func load(container: AppServiceContainer) {
        container.groupService.currentGroup
            .sink { [weak self] group in
                self?.groupName = group.name
                if let inviter = group.members.first {
                    self?.inviterName = inviter.name
                }
            }
            .store(in: &cancellables)
        
        container.challengeService.challenges
            .sink { [weak self] challenges in
                if let challenge = challenges.first(where: { $0.status == .active }) {
                    self?.buyInAmount = challenge.buyIn
                } else {
                    self?.buyInAmount = 500.00
                }
            }
            .store(in: &cancellables)
    }
    
    func connectAndDeposit(onJoin: @escaping () -> Void) {
        isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.isLoading = false
            onJoin()
        }
    }
}
