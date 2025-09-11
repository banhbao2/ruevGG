import Foundation

@MainActor
class TeamAnalysisManager: ObservableObject {
    @Published var teamStats: TeamStats?
    @Published var playerPerformances: [String: PlayerPerformanceSummary] = [:]
    @Published var isAnalyzing: Bool = false
    @Published var analysisProgress: String = ""
    @Published var errorMessage: String = ""
    
    private let riotAPIService = RiotAPIService.shared
    var targetGamesCount = 10
    private let maxMatchHistoryToSearch = 100
    
    private var matchHistoryCache: [String: [String]] = [:]
    private let rateLimiter = RateLimiter()
    
    func analyzeTeamPerformance(players: [CompletePlayer]) async {
        guard players.count >= 2 else { return }
        
        isAnalyzing = true
        teamStats = nil
        playerPerformances.removeAll()
        matchHistoryCache.removeAll()
        analysisProgress = "Fetching match histories..."
        
        var stats = TeamStats(players: players)
        
        for player in players {
            playerPerformances[player.puuid] = PlayerPerformanceSummary(player: player)
        }
        
        // Fetch match histories in parallel
        await fetchAllMatchHistories(players: players)
        
        analysisProgress = "Finding games where all \(players.count) players played together..."
        await findAndAnalyzeTeamGames(players: players, stats: &stats)
        
        teamStats = stats
        isAnalyzing = false
        analysisProgress = ""
    }
    
    private func fetchAllMatchHistories(players: [CompletePlayer]) async {
        await withTaskGroup(of: Void.self) { group in
            for player in players {
                group.addTask {
                    await self.fetchMatchHistoryForPlayer(player)
                }
            }
        }
    }
    
    private func fetchMatchHistoryForPlayer(_ player: CompletePlayer) async {
        var allMatches: [String] = []
        
        for start in stride(from: 0, to: maxMatchHistoryToSearch, by: 20) {
            do {
                await rateLimiter.waitForToken()
                let matches = try await riotAPIService.fetchMatchHistory(
                    for: player.puuid,
                    start: start,
                    count: min(20, maxMatchHistoryToSearch - start)
                )
                allMatches.append(contentsOf: matches)
                
                if matches.count < 20 {
                    break
                }
            } catch {
                print("Failed to fetch matches for \(player.displayName): \(error)")
                break
            }
        }
        
        matchHistoryCache[player.puuid] = allMatches
    }
    
    private func findAndAnalyzeTeamGames(players: [CompletePlayer], stats: inout TeamStats) async {
        let allPlayerMatches = players.compactMap { matchHistoryCache[$0.puuid] }
        
        guard allPlayerMatches.count == players.count else {
            errorMessage = "Failed to fetch match history for all players"
            return
        }
        
        // Find common matches
        var commonMatches = Set(allPlayerMatches[0])
        for playerMatches in allPlayerMatches.dropFirst() {
            commonMatches = commonMatches.intersection(Set(playerMatches))
        }
        
        let matchesToAnalyze = Array(commonMatches.prefix(targetGamesCount * 2))
        
        var gamesFoundTogether = 0
        
        for matchId in matchesToAnalyze {
            if gamesFoundTogether >= targetGamesCount {
                break
            }
            
            analysisProgress = "Found \(gamesFoundTogether)/\(targetGamesCount) team games..."
            
            do {
                await rateLimiter.waitForToken()
                let matchDetails = try await riotAPIService.fetchMatchDetails(
                    matchId: matchId,
                    region: "europe"
                )
                
                // Find all players in the match
                let playerStats = players.compactMap { player in
                    matchDetails.info.participants.first(where: { $0.puuid == player.puuid })
                }
                
                // Check if all players were found and on the same team
                if playerStats.count == players.count {
                    let firstTeamId = playerStats[0].teamId
                    let allSameTeam = playerStats.allSatisfy { $0.teamId == firstTeamId }
                    
                    if allSameTeam {
                        gamesFoundTogether += 1
                        stats.gamesPlayedTogether += 1
                        
                        let won = playerStats[0].win
                        let queueId = matchDetails.info.queueId
                        let modeName = GameModeHelper.getModeName(for: queueId)
                        
                        if won {
                            stats.wins += 1
                        } else {
                            stats.losses += 1
                        }
                        
                        // Update mode-specific stats
                        if stats.gamesByMode[queueId] != nil {
                            stats.gamesByMode[queueId]!.games += 1
                            if won {
                                stats.gamesByMode[queueId]!.wins += 1
                            } else {
                                stats.gamesByMode[queueId]!.losses += 1
                            }
                        } else {
                            var modeStats = GameModeStats(modeName: modeName, queueId: queueId)
                            modeStats.games = 1
                            if won {
                                modeStats.wins = 1
                            } else {
                                modeStats.losses = 1
                            }
                            stats.gamesByMode[queueId] = modeStats
                        }
                        
                        // Store individual player performance data
                        for (player, playerStat) in zip(players, playerStats) {
                            let matchData = PlayerMatchData(
                                matchId: matchId,
                                championName: playerStat.championName,
                                kills: playerStat.kills,
                                deaths: playerStat.deaths,
                                assists: playerStat.assists,
                                totalCS: playerStat.totalCS,
                                gameDuration: matchDetails.info.gameDuration,
                                win: playerStat.win,
                                queueId: queueId,
                                modeName: modeName,
                                teamPosition: playerStat.individualPosition,
                                totalDamageDealt: playerStat.totalDamageDealtToChampions ?? 0,
                                totalDamageTaken: playerStat.totalDamageTaken ?? 0,
                                goldEarned: playerStat.goldEarned ?? 0,
                                visionScore: playerStat.visionScore ?? 0,
                                gameCreation: Date(timeIntervalSince1970: Double(matchDetails.info.gameCreation) / 1000)
                            )
                            
                            playerPerformances[player.puuid]?.matches.append(matchData)
                        }
                    }
                }
            } catch {
                print("Failed to fetch match \(matchId): \(error)")
                // Continue with next match instead of stopping
            }
        }
        
        if gamesFoundTogether == 0 {
            errorMessage = "No games found where these players played together"
        }
    }
    
    func reset() {
        teamStats = nil
        playerPerformances.removeAll()
        matchHistoryCache.removeAll()
        isAnalyzing = false
        analysisProgress = ""
        errorMessage = ""
    }
}
