import Foundation

struct Setlist: Codable, Identifiable {
    var id: UUID
    var name: String
    var date: Date
    var songIDs: [UUID]       // ordine della serata — referenze al catalogo
}

extension Setlist {
    static func makeDefault() -> Setlist {
        Setlist(
            id: UUID(),
            name: "Nuova setlist",
            date: Date(),
            songIDs: []
        )
    }
}
