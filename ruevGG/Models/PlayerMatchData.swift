import Foundation

// MARK: - Player Match Performance Data
struct PlayerMatchData: Identifiable {
    let id = UUID()
    let matchId: String
    let championName: String
    let kills: Int
    let deaths: Int
    let assists: Int
    let totalCS: Int
    let gameDuration: Int // in seconds
    let win: Bool
    let queueId: Int
    let modeName: String
    let teamPosition: String
    let totalDamageDealt: Int
    let totalDamageTaken: Int
    let goldEarned: Int
    let visionScore: Int
    let gameCreation: Date
    
    // Computed properties
    var kda: Double {
        let divisor = deaths == 0 ? 1 : deaths
        return Double(kills + assists) / Double(divisor)
    }
    
    var csPerMinute: Double {
        let minutes = Double(gameDuration) / 60.0
        return minutes > 0 ? Double(totalCS) / minutes : 0
    }
    
    var goldPerMinute: Double {
        let minutes = Double(gameDuration) / 60.0
        return minutes > 0 ? Double(goldEarned) / minutes : 0
    }
    
    var kdaString: String {
        "\(kills)/\(deaths)/\(assists)"
    }
    
    var gameDurationFormatted: String {
        let minutes = gameDuration / 60
        let seconds = gameDuration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Player Performance Summary
struct PlayerPerformanceSummary {
    let player: CompletePlayer
    var matches: [PlayerMatchData] = []
    
    // Overall stats
    var totalGames: Int { matches.count }
    var wins: Int { matches.filter { $0.win }.count }
    var losses: Int { totalGames - wins }
    var winRate: Double {
        totalGames > 0 ? (Double(wins) / Double(totalGames)) * 100 : 0
    }
    
    // KDA stats
    var totalKills: Int { matches.reduce(0) { $0 + $1.kills } }
    var totalDeaths: Int { matches.reduce(0) { $0 + $1.deaths } }
    var totalAssists: Int { matches.reduce(0) { $0 + $1.assists } }
    
    var averageKills: Double {
        totalGames > 0 ? Double(totalKills) / Double(totalGames) : 0
    }
    
    var averageDeaths: Double {
        totalGames > 0 ? Double(totalDeaths) / Double(totalGames) : 0
    }
    
    var averageAssists: Double {
        totalGames > 0 ? Double(totalAssists) / Double(totalGames) : 0
    }
    
    var averageKDA: Double {
        let divisor = totalDeaths == 0 ? 1 : totalDeaths
        return Double(totalKills + totalAssists) / Double(divisor)
    }
    
    // CS stats
    var averageCS: Double {
        totalGames > 0 ? Double(matches.reduce(0) { $0 + $1.totalCS }) / Double(totalGames) : 0
    }
    
    var averageCSPerMinute: Double {
        totalGames > 0 ? matches.reduce(0.0) { $0 + $1.csPerMinute } / Double(totalGames) : 0
    }
    
    // Gold stats
    var averageGold: Double {
        totalGames > 0 ? Double(matches.reduce(0) { $0 + $1.goldEarned }) / Double(totalGames) : 0
    }
    
    var averageGoldPerMinute: Double {
        totalGames > 0 ? matches.reduce(0.0) { $0 + $1.goldPerMinute } / Double(totalGames) : 0
    }
    
    // Damage stats
    var averageDamageDealt: Double {
        totalGames > 0 ? Double(matches.reduce(0) { $0 + $1.totalDamageDealt }) / Double(totalGames) : 0
    }
    
    var averageDamageTaken: Double {
        totalGames > 0 ? Double(matches.reduce(0) { $0 + $1.totalDamageTaken }) / Double(totalGames) : 0
    }
    
    // Vision stats
    var averageVisionScore: Double {
        totalGames > 0 ? Double(matches.reduce(0) { $0 + $1.visionScore }) / Double(totalGames) : 0
    }
    
    // Champion stats
    var championStats: [ChampionPerformance] {
        let grouped = Dictionary(grouping: matches, by: { $0.championName })
        return grouped.map { (champion, matches) in
            ChampionPerformance(
                championName: champion,
                gamesPlayed: matches.count,
                wins: matches.filter { $0.win }.count,
                losses: matches.filter { !$0.win }.count,
                averageKDA: matches.reduce(0.0) { $0 + $1.kda } / Double(matches.count),
                totalKills: matches.reduce(0) { $0 + $1.kills },
                totalDeaths: matches.reduce(0) { $0 + $1.deaths },
                totalAssists: matches.reduce(0) { $0 + $1.assists }
            )
        }.sorted { $0.gamesPlayed > $1.gamesPlayed }
    }
    
    // Position stats
    var positionStats: [PositionPerformance] {
        let grouped = Dictionary(grouping: matches, by: { $0.teamPosition })
        return grouped.map { (position, matches) in
            PositionPerformance(
                position: position.isEmpty ? "FILL" : position,
                gamesPlayed: matches.count,
                wins: matches.filter { $0.win }.count,
                losses: matches.filter { !$0.win }.count
            )
        }.sorted { $0.gamesPlayed > $1.gamesPlayed }
    }
    
    // Best/Worst games
    var bestKDAGame: PlayerMatchData? {
        matches.max(by: { $0.kda < $1.kda })
    }
    
    var worstKDAGame: PlayerMatchData? {
        matches.min(by: { $0.kda < $1.kda })
    }
    
    var highestKillGame: PlayerMatchData? {
        matches.max(by: { $0.kills < $1.kills })
    }
    
    var highestCSGame: PlayerMatchData? {
        matches.max(by: { $0.totalCS < $1.totalCS })
    }
    
    // Filter methods
    func filteredByGameMode(_ queueId: Int?) -> PlayerPerformanceSummary {
        guard let queueId = queueId else { return self }
        
        var filtered = self
        filtered.matches = matches.filter { $0.queueId == queueId }
        return filtered
    }
}

// MARK: - Champion Performance
struct ChampionPerformance: Identifiable {
    let id = UUID()
    let championName: String
    let gamesPlayed: Int
    let wins: Int
    let losses: Int
    let averageKDA: Double
    let totalKills: Int
    let totalDeaths: Int
    let totalAssists: Int
    
    var winRate: Double {
        gamesPlayed > 0 ? (Double(wins) / Double(gamesPlayed)) * 100 : 0
    }
    
    var kdaString: String {
        let avgK = gamesPlayed > 0 ? Double(totalKills) / Double(gamesPlayed) : 0
        let avgD = gamesPlayed > 0 ? Double(totalDeaths) / Double(gamesPlayed) : 0
        let avgA = gamesPlayed > 0 ? Double(totalAssists) / Double(gamesPlayed) : 0
        return String(format: "%.1f/%.1f/%.1f", avgK, avgD, avgA)
    }
}

// MARK: - Position Performance
struct PositionPerformance: Identifiable {
    let id = UUID()
    let position: String
    let gamesPlayed: Int
    let wins: Int
    let losses: Int
    
    var winRate: Double {
        gamesPlayed > 0 ? (Double(wins) / Double(gamesPlayed)) * 100 : 0
    }
    
    var displayName: String {
        switch position.uppercased() {
        case "TOP": return "Top"
        case "JUNGLE": return "Jungle"
        case "MIDDLE": return "Mid"
        case "BOTTOM": return "ADC"
        case "UTILITY": return "Support"
        case "FILL", "": return "Fill"
        default: return position
        }
    }
    
    var icon: String {
        switch position.uppercased() {
        case "TOP": return "shield.fill"
        case "JUNGLE": return "leaf.fill"
        case "MIDDLE": return "sparkles"
        case "BOTTOM": return "scope"
        case "UTILITY": return "heart.fill"
        default: return "questionmark.circle"
        }
    }
}
