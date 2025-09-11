import Foundation

struct GameModeStats {
    var modeName: String
    var queueId: Int
    var games: Int = 0
    var wins: Int = 0
    var losses: Int = 0
    
    var winRate: Double {
        let total = wins + losses
        return total > 0 ? (Double(wins) / Double(total)) * 100 : 0
    }
}

struct TeamStats: Identifiable {
    let id = UUID()
    let players: [CompletePlayer]
    var gamesPlayedTogether: Int = 0
    var wins: Int = 0
    var losses: Int = 0
    var gamesByMode: [Int: GameModeStats] = [:]
    
    var winRate: Double {
        let total = wins + losses
        return total > 0 ? (Double(wins) / Double(total)) * 100 : 0
    }
    
    var playerNames: String {
        players.map { $0.displayName }.joined(separator: ", ")
    }
    
    var sortedGameModes: [GameModeStats] {
        gamesByMode.values.sorted { $0.games > $1.games }
    }
}

struct GameModeHelper {
    static func getModeName(for queueId: Int) -> String {
        switch queueId {
        case 420: return "Ranked Solo/Duo"
        case 440: return "Ranked Flex"
        case 450: return "ARAM"
        case 400: return "Normal Draft"
        case 430: return "Normal Blind"
        case 700: return "Clash"
        case 830, 840, 850: return "Co-op vs AI"
        case 900: return "URF"
        case 920: return "Legend of the Poro King"
        case 1020: return "One for All"
        case 1300: return "Nexus Blitz"
        case 1400: return "Ultimate Spellbook"
        case 1700: return "Arena"
        case 490: return "Quickplay"
        default: return "Other Mode"
        }
    }
    
    static func getModeCategory(for queueId: Int) -> String {
        switch queueId {
        case 420, 440: return "Ranked"
        case 450: return "ARAM"
        case 400, 430, 490: return "Normal"
        case 900, 920, 1020, 1300, 1400, 1700: return "Special"
        default: return "Other"
        }
    }
}
