import Combine
import Foundation

protocol PIXUseCaseProtocol {
    // For now, PIX keys are mock but they should eventually come from a service
    // Adding a placeholder for service dependency
    func fetchKeys() async -> [PIXKey]
}

final class PIXUseCase: PIXUseCaseProtocol {
    private let userService: any UserServiceProtocol
    
    init(userService: any UserServiceProtocol) {
        self.userService = userService
    }
    
    func fetchKeys() async -> [PIXKey] {
        // Mock data as seen in the original ViewModel
        return [
            PIXKey(id: UUID(), type: .email, value: "joao.silva@email.com"),
            PIXKey(id: UUID(), type: .cpf, value: "***.456.789-**")
        ]
    }
}
