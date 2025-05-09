import Foundation

enum CardRarity: String, CaseIterable {
    case common
    case rare
    case epic
    case legendary
    case HolyT
    case Season1
    case holographicEX

    // Définir l'ordre de tri
    var sortOrder: Int {
        switch self {
        case .holographicEX: return 7
        case .Season1: return 6
        case .HolyT: return 5
        case .legendary: return 4
        case .epic: return 3
        case .rare: return 2
        case .common: return 1
        }
    }
}

// Assuming CardRarity enum definition is above or in this file and is Equatable/Hashable
struct BoosterCard: Identifiable, Equatable, Hashable {
    var id: Int { number } // Using number as the unique identifier
    let name: String
    let rarity: CardRarity
    let number: Int

    // If CardRarity is a simple enum, Equatable and Hashable can be synthesized.
    // If not, you might need to implement them manually.
    // static func == (lhs: BoosterCard, rhs: BoosterCard) -> Bool {
    //     return lhs.number == rhs.number // Or compare all properties
    // }

    // func hash(into hasher: inout Hasher) {
    //     hasher.combine(number) // Or combine all properties
    // }
}
