// PIXServiceProtocol.swift

import Foundation

protocol PIXServiceProtocol: AnyObject {

    // MARK: - Actions

    func fetchKeys() async -> [PIXKey]
}
