// UserServiceProtocol.swift

import Combine
import Foundation

protocol UserServiceProtocol {

    // MARK: - State

    var currentUser: AnyPublisher<User, Never> { get }

    // MARK: - Actions

    func updateUser(_ user: User) async throws
    func deposit(amount: Decimal) async throws
}
