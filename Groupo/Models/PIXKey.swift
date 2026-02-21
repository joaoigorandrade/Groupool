import Foundation

struct PIXKey: Identifiable, Hashable {
    let id: UUID
    let type: PIXKeyType
    let value: String
    
    enum PIXKeyType: String, CaseIterable, Identifiable {
        case cpf = "CPF"
        case email = "Email"
        case phone = "Phone"
        case random = "Random Key"
        
        var id: String { self.rawValue }
    }
}
