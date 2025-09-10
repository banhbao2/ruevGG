import Foundation

// MARK: - Team Analysis Models
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
    var gamesByMode: [Int: GameModeStats] = [:] // queueId -> GameModeStats
    
    var winRate: Double {
        let total = wins + losses
        return total > 0 ? (Double(wins) / Double(total)) * 100 : 0
    }
    
    var playerNames: String {
        players.map { $0.displayName }.joined(separator: ", ")
    }
    
    // Get sorted game modes by number of games
    var sortedGameModes: [GameModeStats] {
        gamesByMode.values.sorted { $0.games > $1.games }
    }
}

// MARK: - Game Mode Mappings
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

// MARK: - Team Analysis Manager
@MainActor
class TeamAnalysisManager: ObservableObject {
    @Published var teamStats: TeamStats?
    @Published var isAnalyzing: Bool = false
    @Published var analysisProgress: String = ""
    @Published var errorMessage: String = ""
    
    private let riotAPIService = RiotAPIService.shared
    var targetGamesCount = 10 // Target number of games played together to find
    private let maxMatchHistoryToSearch = 100 // Maximum matches to search through per player
    
    // Cache for match histories to avoid duplicate API calls
    private var matchHistoryCache: [String: [String]] = [:]
    
    // Rate limiting properties
    private let requestDelay: UInt64 = 1_200_000_000 // 1.2 seconds between requests
    private var lastRequestTime: Date = Date.distantPast
    
    func analyzeTeamPerformance(players: [CompletePlayer]) async {
        guard players.count >= 2 else { return }
        
        isAnalyzing = true
        teamStats = nil
        matchHistoryCache.removeAll() // Clear cache for new analysis
        analysisProgress = "Fetching match histories..."
        
        // Initialize team stats
        var stats = TeamStats(players: players)
        
        // First, fetch initial match histories for all players
        for player in players {
            await fetchInitialMatchHistory(for: player)
        }
        
        // Find games where ALL players played together
        analysisProgress = "Finding games where all \(players.count) players played together..."
        await findTeamGames(players: players, stats: &stats)
        
        // Store the final stats
        teamStats = stats
        
        isAnalyzing = false
        analysisProgress = ""
    }
    
    private func fetchInitialMatchHistory(for player: CompletePlayer) async {
        // Fetch initial batch of matches (start with 20 to be efficient)
        await fetchMatchHistoryBatch(for: player, count: 20, startIndex: 0)
    }
    
    private func fetchMatchHistoryBatch(for player: CompletePlayer, count: Int, startIndex: Int) async {
        // Calculate delay needed for rate limiting
        let timeSinceLastRequest = Date().timeIntervalSince(lastRequestTime)
        let minimumDelay = 1.2 // seconds
        
        if timeSinceLastRequest < minimumDelay {
            let additionalDelay = minimumDelay - timeSinceLastRequest
            analysisProgress = "Waiting for rate limit... (\(Int(additionalDelay))s)"
            try? await Task.sleep(nanoseconds: UInt64(additionalDelay * 1_000_000_000))
        }
        
        analysisProgress = "Fetching matches for \(player.displayName)..."
        
        do {
            // Fetch matches with start index for pagination
            let urlString = "https://europe.api.riotgames.com/lol/match/v5/matches/by-puuid/\(player.puuid)/ids?start=\(startIndex)&count=\(count)"
            
            guard let url = URL(string: urlString) else {
                print("❌ Invalid URL for match history")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue(riotAPIService.apiKey, forHTTPHeaderField: "X-Riot-Token")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("❌ Failed to fetch matches for \(player.displayName)")
                matchHistoryCache[player.puuid] = matchHistoryCache[player.puuid] ?? []
                return
            }
            
            let matches = try JSONDecoder().decode([String].self, from: data)
            
            // Append to existing cache or create new
            if var existingMatches = matchHistoryCache[player.puuid] {
                existingMatches.append(contentsOf: matches)
                matchHistoryCache[player.puuid] = existingMatches
            } else {
                matchHistoryCache[player.puuid] = matches
            }
            
            lastRequestTime = Date()
            
            print("✅ Fetched \(matches.count) matches for \(player.displayName) (total cached: \(matchHistoryCache[player.puuid]?.count ?? 0))")
            
        } catch {
            print("❌ Failed to fetch matches for \(player.displayName): \(error)")
            // Initialize empty cache to prevent retry
            if matchHistoryCache[player.puuid] == nil {
                matchHistoryCache[player.puuid] = []
            }
        }
    }
    
    private func findTeamGames(players: [CompletePlayer], stats: inout TeamStats) async {
        var gamesFoundTogether = 0
        var matchesSearched = 0
        var currentBatchSize = 0
        
        // Continue searching until we find target games or hit the max search limit
        while gamesFoundTogether < targetGamesCount && currentBatchSize < maxMatchHistoryToSearch {
            // Get all cached match histories
            let allPlayerMatches = players.compactMap { matchHistoryCache[$0.puuid] }
            
            // If any player doesn't have matches cached, something went wrong
            guard allPlayerMatches.count == players.count else {
                print("⚠️ Not all players have cached matches")
                return
            }
            
            // Find common matches (games where ALL players participated)
            var commonMatches = Set(allPlayerMatches[0])
            for playerMatches in allPlayerMatches.dropFirst() {
                commonMatches = commonMatches.intersection(Set(playerMatches))
            }
            
            // Filter out already analyzed matches
            let newMatchesToAnalyze = Array(commonMatches).suffix(from: matchesSearched)
            
            if newMatchesToAnalyze.isEmpty && currentBatchSize < maxMatchHistoryToSearch {
                // Need to fetch more matches
                let nextBatchSize = min(20, maxMatchHistoryToSearch - currentBatchSize)
                
                analysisProgress = "Searching deeper in match history..."
                
                // Fetch more matches for all players
                for player in players {
                    await fetchMatchHistoryBatch(for: player, count: nextBatchSize, startIndex: currentBatchSize)
                }
                
                currentBatchSize += nextBatchSize
                continue
            }
            
            // Analyze new common matches
            for matchId in newMatchesToAnalyze {
                if gamesFoundTogether >= targetGamesCount {
                    break
                }
                
                matchesSearched += 1
                analysisProgress = "Found \(gamesFoundTogether)/\(targetGamesCount) team games..."
                
                // Rate limiting for match details
                let timeSinceLastRequest = Date().timeIntervalSince(lastRequestTime)
                let minimumDelay = 1.2 // seconds
                
                if timeSinceLastRequest < minimumDelay {
                    let additionalDelay = minimumDelay - timeSinceLastRequest
                    try? await Task.sleep(nanoseconds: UInt64(additionalDelay * 1_000_000_000))
                }
                
                do {
                    let matchDetails = try await riotAPIService.fetchMatchDetails(
                        matchId: matchId,
                        region: "europe"
                    )
                    lastRequestTime = Date()
                    
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
                            
                            // Update overall stats
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
                            
                            print("  Game \(gamesFoundTogether): \(won ? "WIN" : "LOSS") - \(modeName)")
                        } else {
                            print("  Match \(matchId): Players on different teams (not counted)")
                        }
                    }
                    
                } catch {
                    print("❌ Failed to fetch match \(matchId): \(error)")
                    
                    // If we hit rate limit mid-analysis, wait longer
                    if let apiError = error as? APIError, apiError == .requestFailed {
                        analysisProgress = "Rate limit hit, waiting..."
                        try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 second wait
                    }
                }
            }
            
            // If we've searched all common matches and haven't found enough games
            if newMatchesToAnalyze.isEmpty || matchesSearched >= commonMatches.count {
                // Try to fetch more matches if we haven't hit the limit
                if currentBatchSize < maxMatchHistoryToSearch {
                    let nextBatchSize = min(20, maxMatchHistoryToSearch - currentBatchSize)
                    
                    analysisProgress = "Searching deeper in match history..."
                    
                    for player in players {
                        await fetchMatchHistoryBatch(for: player, count: nextBatchSize, startIndex: currentBatchSize)
                    }
                    
                    currentBatchSize += nextBatchSize
                } else {
                    // We've hit the max search limit
                    break
                }
            }
        }
        
        print("📊 Final team stats for \(players.count) players:")
        print("   Games together found: \(stats.gamesPlayedTogether) (target was \(targetGamesCount))")
        print("   Wins: \(stats.wins), Losses: \(stats.losses)")
        print("   Win rate: \(String(format: "%.1f%%", stats.winRate))")
        print("   Game modes: \(stats.sortedGameModes.map { "\($0.modeName): \($0.games)" }.joined(separator: ", "))")
        print("   Total matches searched: \(matchesSearched)")
    }
    
    func reset() {
        teamStats = nil
        matchHistoryCache.removeAll()
        isAnalyzing = false
        analysisProgress = ""
        errorMessage = ""
    }
}
