// GroupServiceProtocol.swift

import Combine
import Foundation

protocol GroupServiceProtocol {

    // MARK: - State

    var currentGroup: AnyPublisher<Group, Never> { get }
}
