import Foundation

struct Group: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let totalPool: Decimal
    let members: [User]

    func updating(
        name: String? = nil,
        totalPool: Decimal? = nil,
        members: [User]? = nil
    ) -> Group {
        Group(
            id: id,
            name: name ?? self.name,
            totalPool: totalPool ?? self.totalPool,
            members: members ?? self.members
        )
    }
}
