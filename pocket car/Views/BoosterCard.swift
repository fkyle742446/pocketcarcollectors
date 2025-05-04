import Foundation

enum CardRarity: String {
    case common
    case rare
    case epic
    case legendary
    case HolyT
    case Season1

    // Définir l'ordre de tri
    var sortOrder: Int {
        switch self {
        case .Season1: return 6
        case .HolyT: return 5
        case .legendary: return 4
        case .epic: return 3
        case .rare: return 2
        case .common: return 1
        }
    }
}

struct BoosterCard: Identifiable {
    let id = UUID()
    let name: String
    let rarity: CardRarity
    let number: Int
    
    init(name: String, rarity: CardRarity, number: Int) {
        self.name = name
        self.rarity = rarity
        self.number = number
    }
} 
