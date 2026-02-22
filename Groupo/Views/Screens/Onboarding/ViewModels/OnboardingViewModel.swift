import Foundation
import Observation

@Observable
final class OnboardingViewModel {
    var groupName: String = "Loading..."
    var inviterName: String = "Loading..."
    var buyInAmount: Decimal = 0
    var rules: [String] = []
    var isLoading: Bool = false
    
    private let onboardingUseCase: OnboardingUseCaseProtocol
    
    init(onboardingUseCase: OnboardingUseCaseProtocol) {
        self.onboardingUseCase = onboardingUseCase
    }
    
    @MainActor
    func load() async {
        isLoading = true
        do {
            let details = try await onboardingUseCase.fetchInviteDetails()
            self.groupName = details.groupName
            self.inviterName = details.inviterName
            self.buyInAmount = details.buyInAmount
            self.rules = details.rules
        } catch {
            print("Failed to load onboarding details: \(error)")
        }
        isLoading = false
    }
    
    @MainActor
    func connectAndDeposit(onJoin: @escaping () -> Void) async {
        isLoading = true
        do {
            try await onboardingUseCase.connectAndDeposit()
            onJoin()
        } catch {
            print("Failed to deposit: \(error)")
        }
        isLoading = false
    }
}
