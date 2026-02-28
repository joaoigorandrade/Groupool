// UserServiceProtocol.swift

import Foundation

protocol UserServiceProtocol: AnyObject {

    // MARK: - State

    var currentUser: User { get }

    // MARK: - Actions

    func refresh() async
    func updateUser(_ user: User) async throws
    func deposit(amount: Decimal) async throws
}
