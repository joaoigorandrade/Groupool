import Foundation

struct Group: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let totalPool: Decimal
    let members: [User]
}
