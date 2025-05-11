import Foundation

enum CardRarity: String, CaseIterable {
    case common
    case rare
    case epic
    case legendary
    case referral
    case HolyT
    case Season1
    case holographicEX

    // Définir l'ordre de tri
    var sortOrder: Int {
        switch self {
        case .holographicEX: return 8
        case .Season1: return 7
        case .HolyT: return 6
        case .referral: return 5
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
    let imageName: String // <-- Ensure this line is present
    
    // Ensure this initializer is present and matches
    init(name: String, rarity: CardRarity, number: Int, imageName: String? = nil) {
        self.name = name
        self.rarity = rarity
        self.number = number
        self.imageName = imageName ?? name
        
        
        // If CardRarity is a simple enum, Equatable and Hashable can be synthesized.
        // If not, you might need to implement them manually.
        // static func == (lhs: BoosterCard, rhs: BoosterCard) -> Bool {
        //     return lhs.number == rhs.number // Or compare all properties
        // }
        
        // func hash(into hasher: inout Hasher) {
        //     hasher.combine(number) // Or combine all properties
        // }
    }
}
