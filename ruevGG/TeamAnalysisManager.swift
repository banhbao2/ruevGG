import Foundation

// MARK: - Duo Analysis Models
struct DuoStats: Identifiable {
    let id = UUID()
    let player1: CompletePlayer
    let player2: CompletePlayer
    var gamesPlayedTogether: Int = 0
    var wins: Int = 0
    var losses: Int = 0
    
    var winRate: Double {
        let total = wins + losses
        return total > 0 ? (Double(wins) / Double(total)) * 100 : 0
    }
}

struct DuoGameDetails {
    let matchId: String
    let player1Stats: ParticipantDetails
    let player2Stats: ParticipantDetails
    let won: Bool
    let gameDuration: Int
}

// MARK: - Duo Analysis Manager
@MainActor
class DuoAnalysisManager: ObservableObject {
    @Published var duoStats: [DuoStats] = []
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
    
    func analyzeDuoPerformance(players: [CompletePlayer]) async {
        guard players.count >= 2 else { return }
        
        isAnalyzing = true
        duoStats.removeAll()
        matchHistoryCache.removeAll() // Clear cache for new analysis
        analysisProgress = "Fetching match histories..."
        
        // First, fetch initial match histories with rate limiting
        for player in players {
            if matchHistoryCache[player.puuid] == nil {
                await fetchInitialMatchHistory(for: player)
            }
        }
        
        // Now analyze all possible duo combinations using cached data
        analysisProgress = "Analyzing duo combinations..."
        for i in 0..<players.count {
            for j in (i+1)..<players.count {
                let player1 = players[i]
                let player2 = players[j]
                
                await analyzePlayerPairUntilTarget(player1: player1, player2: player2)
            }
        }
        
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
    
    private func analyzePlayerPairUntilTarget(player1: CompletePlayer, player2: CompletePlayer) async {
        analysisProgress = "Finding games with \(player1.displayName) & \(player2.displayName)..."
        
        var duoStat = DuoStats(player1: player1, player2: player2)
        var gamesFoundTogether = 0
        var matchesSearched = 0
        var currentBatchSize = 0
        
        // Continue searching until we find target games or hit the max search limit
        while gamesFoundTogether < targetGamesCount && matchesSearched < maxMatchHistoryToSearch {
            // Get cached match histories
            guard let player1Matches = matchHistoryCache[player1.puuid],
                  let player2Matches = matchHistoryCache[player2.puuid] else {
                print("⚠️ No cached matches for duo analysis")
                duoStats.append(duoStat)
                return
            }
            
            // Find common matches from current cache
            let commonMatches = Set(player1Matches).intersection(Set(player2Matches))
            
            // Filter out already analyzed matches
            let newMatchesToAnalyze = Array(commonMatches).suffix(from: matchesSearched)
            
            if newMatchesToAnalyze.isEmpty && currentBatchSize < maxMatchHistoryToSearch {
                // Need to fetch more matches
                let nextBatchSize = min(20, maxMatchHistoryToSearch - currentBatchSize)
                
                analysisProgress = "Searching more match history for \(player1.displayName) & \(player2.displayName)..."
                
                // Fetch more matches for both players
                await fetchMatchHistoryBatch(for: player1, count: nextBatchSize, startIndex: currentBatchSize)
                await fetchMatchHistoryBatch(for: player2, count: nextBatchSize, startIndex: currentBatchSize)
                
                currentBatchSize += nextBatchSize
                continue
            }
            
            // Analyze new common matches
            for matchId in newMatchesToAnalyze {
                if gamesFoundTogether >= targetGamesCount {
                    break
                }
                
                matchesSearched += 1
                analysisProgress = "Found \(gamesFoundTogether)/\(targetGamesCount) games together..."
                
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
                    
                    // Find both players in the match
                    if let p1Stats = matchDetails.info.participants.first(where: { $0.puuid == player1.puuid }),
                       let p2Stats = matchDetails.info.participants.first(where: { $0.puuid == player2.puuid }) {
                        
                        // Check if they were on the same team
                        if p1Stats.teamId == p2Stats.teamId {
                            gamesFoundTogether += 1
                            duoStat.gamesPlayedTogether += 1
                            
                            if p1Stats.win {
                                duoStat.wins += 1
                            } else {
                                duoStat.losses += 1
                            }
                            
                            print("  Game \(gamesFoundTogether): \(p1Stats.win ? "WIN" : "LOSS") - Same team")
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
                    
                    await fetchMatchHistoryBatch(for: player1, count: nextBatchSize, startIndex: currentBatchSize)
                    await fetchMatchHistoryBatch(for: player2, count: nextBatchSize, startIndex: currentBatchSize)
                    
                    currentBatchSize += nextBatchSize
                } else {
                    // We've hit the max search limit
                    break
                }
            }
        }
        
        print("📊 Final stats for \(player1.displayName) & \(player2.displayName):")
        print("   Games together found: \(duoStat.gamesPlayedTogether) (target was \(targetGamesCount))")
        print("   Wins: \(duoStat.wins), Losses: \(duoStat.losses)")
        print("   Win rate: \(String(format: "%.1f%%", duoStat.winRate))")
        print("   Total matches searched: \(matchesSearched)")
        
        // Add the duo stats to the results
        duoStats.append(duoStat)
    }
    
    func reset() {
        duoStats.removeAll()
        matchHistoryCache.removeAll()
        isAnalyzing = false
        analysisProgress = ""
        errorMessage = ""
    }
}

