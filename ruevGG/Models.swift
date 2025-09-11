import Foundation

struct Account: Codable {
    let puuid: String
    let gameName: String
    let tagLine: String
}

struct SummonerDetails: Codable {
    let id: String?
    let accountId: String?
    let puuid: String
    let profileIconId: Int
    let revisionDate: Int64
    let summonerLevel: Int
    
    var summonerId: String {
        return id ?? "unknown"
    }
    
    var encryptedAccountId: String {
        return accountId ?? "unknown"
    }
}

struct CompletePlayer {
    let account: Account
    let summoner: SummonerDetails
    
    var displayName: String {
        return "\(account.gameName)#\(account.tagLine)"
    }
    
    var level: Int {
        return summoner.summonerLevel
    }
    
    // Expose profile icon ID for easy access
    var profileIconId: Int {
        return summoner.profileIconId
    }
    
    var puuid: String {
        return account.puuid
    }
}

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
