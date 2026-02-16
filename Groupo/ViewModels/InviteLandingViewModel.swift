
import Combine
import SwiftUI

class InviteLandingViewModel: ObservableObject {
    @Published private(set) var groupName: String
    @Published private(set) var inviterName: String
    @Published private(set) var buyInAmount: Decimal
    @Published private(set) var rules: [String]
    
    init() {
        self.groupName = "Férias em Noronha 2024"
        self.inviterName = "Alice Silva"
        self.buyInAmount = 500.00
        self.rules = [
            "1. Os depósitos são finais e não reembolsáveis.",
            "2. A decisão da maioria é soberana em disputas.",
            "3. O administrador tem voto de minerva."
        ]
    }
    
    func connectAndDeposit() {
        print("Connect PIX & Deposit tapped")
    }
}
