// MockPIXService.swift

import Foundation

final class MockPIXService: PIXServiceProtocol {

    // MARK: - Actions

    func fetchKeys() async -> [PIXKey] {
        [
            PIXKey(id: UUID(), type: .email, value: "joao.silva@email.com"),
            PIXKey(id: UUID(), type: .cpf, value: "***.456.789-**")
        ]
    }
}
