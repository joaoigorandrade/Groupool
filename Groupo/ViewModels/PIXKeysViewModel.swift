import Foundation
import Observation
import SwiftUI

@Observable
class PIXKeysViewModel {
    var keys: [PIXKey] = [
        PIXKey(id: UUID(), type: .email, value: "joao.silva@email.com"),
        PIXKey(id: UUID(), type: .cpf, value: "***.456.789-**")
    ]
    
    var showingAddKeySheet = false
    
    func deleteKey(at offsets: IndexSet) {
        keys.remove(atOffsets: offsets)
    }
    
    func addKey(type: PIXKey.PIXKeyType, value: String) {
        let newKey = PIXKey(id: UUID(), type: type, value: value)
        keys.append(newKey)
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        showingAddKeySheet = false
    }
}
