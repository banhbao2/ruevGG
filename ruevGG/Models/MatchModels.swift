import Foundation

struct MatchDetails: Codable {
    let metadata: MatchMetadata
    let info: MatchInfo
}

struct MatchMetadata: Codable {
    let matchId: String
    let participants: [String]
}

struct MatchInfo: Codable {
    let gameCreation: Int64
    let gameDuration: Int
    let gameMode: String
    let gameType: String
    let queueId: Int
    let participants: [ParticipantDetails]
    let teams: [TeamDetails]
}

struct ParticipantDetails: Codable {
    let puuid: String
    let championName: String
    let kills: Int
    let deaths: Int
    let assists: Int
    let win: Bool
    let teamId: Int
    let individualPosition: String
    let totalMinionsKilled: Int
    let neutralMinionsKilled: Int
    let totalDamageDealtToChampions: Int?
    let totalDamageTaken: Int?
    let goldEarned: Int?
    let visionScore: Int?
    
    var totalCS: Int {
        totalMinionsKilled + neutralMinionsKilled
    }
}

struct TeamDetails: Codable {
    let teamId: Int
    let win: Bool
}
