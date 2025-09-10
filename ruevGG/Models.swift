import Foundation

// Account API Response Model
struct Account: Codable {
    let puuid: String
    let gameName: String
    let tagLine: String
}

// Summoner API Response Model (for getting level, icon, etc.)
struct SummonerDetails: Codable {
    let id: String?           // Optional - not always returned
    let accountId: String?    // Optional - not always returned
    let puuid: String
    let profileIconId: Int
    let revisionDate: Int64
    let summonerLevel: Int
    
    // Note: The 'name' field might not be returned by the puuid endpoint
    // We'll use the gameName from Account instead
    
    // Computed properties for when you need these values
    var summonerId: String {
        return id ?? "unknown"
    }
    
    var encryptedAccountId: String {
        return accountId ?? "unknown"
    }
}

// Combined model for UI display
struct CompletePlayer {
    let account: Account
    let summoner: SummonerDetails
    
    var displayName: String {
        return "\(account.gameName)#\(account.tagLine)"
    }
    
    var level: Int {
        return summoner.summonerLevel
    }
    
    var profileIconId: Int {
        return summoner.profileIconId
    }
    
    var puuid: String {
        return account.puuid
    }
}

// For future duo stats functionality
struct DuoCombo {
    let playerRole: String
    let teammateRole: String
    let wins: Int
    let losses: Int
    var winRate: Double {
        let totalGames = wins + losses
        return totalGames > 0 ? Double(wins) / Double(totalGames) * 100 : 0
    }
}

struct GameResult {
    let gameId: String
    let win: Bool
    let playerKDA: (kills: Int, deaths: Int, assists: Int)
    let teammateKDA: (kills: Int, deaths: Int, assists: Int)
    let playerCS: Int
    let teammateCS: Int
    let gameDuration: Int
    let playerRole: String
    let teammateRole: String
}
