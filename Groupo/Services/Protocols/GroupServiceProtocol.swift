// GroupServiceProtocol.swift

import Foundation

protocol GroupServiceProtocol: AnyObject {

    // MARK: - State

    var currentGroup: Group { get }

    // MARK: - Actions

    func refresh() async
}
