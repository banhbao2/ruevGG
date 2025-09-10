import Foundation

// MARK: - API Error Types
enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorizedAPIKey
    case summonerNotFound
    case requestFailed
    case decodingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorizedAPIKey:
            return "Invalid API Key - Please check your Riot API key"
        case .summonerNotFound:
            return "Summoner not found"
        case .requestFailed:
            return "Request failed"
        case .decodingFailed:
            return "Failed to decode response"
        }
    }
}

// MARK: - Main RiotAPIService Class
class RiotAPIService {
    static let shared = RiotAPIService()
    
    // IMPORTANT: Replace with your actual Riot API key
    var apiKey: String {
        if let url = Bundle.main.url(forResource: "APIKeys", withExtension: "plist"),
           let data = try? Data(contentsOf: url),
           let dict = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
           let key = dict["RIOT_API_KEY"] as? String,
           !key.isEmpty {
            return key
        }
        fatalError("RIOT_API_KEY is missing. Did you create APIKeys.plist and add it to Copy Bundle Resources?")
    }

    private init() {}
    
    // MARK: - Account/Summoner Methods
    
    func fetchSummoner(name: String, tag: String) async throws -> Account {
        let urlString = "https://europe.api.riotgames.com/riot/account/v1/accounts/by-riot-id/\(name)/\(tag)"
        
        print("🔍 Searching for: \(name)#\(tag)")
        print("📡 URL: \(urlString)")
        
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(apiKey, forHTTPHeaderField: "X-Riot-Token")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            print("📡 Status Code: \(httpResponse.statusCode)")
            
            switch httpResponse.statusCode {
            case 200:
                break
            case 401:
                throw APIError.unauthorizedAPIKey
            case 404:
                throw APIError.summonerNotFound
            default:
                throw APIError.requestFailed
            }
            
            let decoder = JSONDecoder()
            do {
                let account = try decoder.decode(Account.self, from: data)
                print("✅ Found account: \(account.gameName)#\(account.tagLine)")
                return account
            } catch {
                print("❌ Decoding error: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📄 Raw response: \(jsonString)")
                }
                throw APIError.decodingFailed
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            print("❌ Network error: \(error)")
            throw APIError.requestFailed
        }
    }
    
    func fetchSummonerByPUUID(_ puuid: String, region: String = "euw1") async throws -> SummonerDetails {
        let urlString = "https://\(region).api.riotgames.com/lol/summoner/v4/summoners/by-puuid/\(puuid)"
        
        print("🔍 Getting summoner details for PUUID: \(puuid)")
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(apiKey, forHTTPHeaderField: "X-Riot-Token")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            print("📡 Summoner Details Status Code: \(httpResponse.statusCode)")
            
            switch httpResponse.statusCode {
            case 200:
                break
            case 401:
                throw APIError.unauthorizedAPIKey
            case 404:
                throw APIError.summonerNotFound
            default:
                throw APIError.requestFailed
            }
            
            let decoder = JSONDecoder()
            do {
                let summonerDetails = try decoder.decode(SummonerDetails.self, from: data)
                print("✅ Got summoner details - Level: \(summonerDetails.summonerLevel)")
                return summonerDetails
            } catch {
                print("❌ Summoner details decoding error: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📄 Raw response: \(jsonString)")
                }
                throw APIError.decodingFailed
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            print("❌ Summoner details network error: \(error)")
            throw APIError.requestFailed
        }
    }
}

// MARK: - Match History Models
struct MatchDetails: Codable {
    let metadata: MatchMetadata
    let info: MatchInfo
}

struct MatchMetadata: Codable {
    let matchId: String
    let participants: [String] // Array of PUUIDs
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
    let individualPosition: String // TOP, JUNGLE, MIDDLE, BOTTOM, UTILITY
    let totalMinionsKilled: Int
    let neutralMinionsKilled: Int
    let totalDamageDealtToChampions: Int?
    let totalDamageTaken: Int?
    let goldEarned: Int?
    let visionScore: Int?
    
    var totalCS: Int {
        return totalMinionsKilled + neutralMinionsKilled
    }
}

struct TeamDetails: Codable {
    let teamId: Int
    let win: Bool
}

// MARK: - RiotAPIService Extensions
extension RiotAPIService {
    
    func fetchMatchHistory(for puuid: String, region: String = "europe", count: Int = 20) async throws -> [String] {
        // Convert server region to routing value for match-v5 API
        let routingRegion = getMatchRegionalEndpoint(for: region)
        let urlString = "https://\(routingRegion).api.riotgames.com/lol/match/v5/matches/by-puuid/\(puuid)/ids?start=0&count=\(count)"
        
        print("🎮 Getting match history from: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(apiKey, forHTTPHeaderField: "X-Riot-Token")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            print("📡 Match History Status Code: \(httpResponse.statusCode)")
            
            switch httpResponse.statusCode {
            case 200:
                break
            case 401:
                throw APIError.unauthorizedAPIKey
            case 404:
                throw APIError.summonerNotFound
            default:
                throw APIError.requestFailed
            }
            
            let decoder = JSONDecoder()
            do {
                let matchIds = try decoder.decode([String].self, from: data)
                print("✅ Successfully got \(matchIds.count) match IDs")
                return matchIds
            } catch {
                print("❌ Match history decoding error: \(error)")
                throw APIError.decodingFailed
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            print("❌ Match history network error: \(error)")
            throw APIError.requestFailed
        }
    }
    
    func fetchMatchDetails(matchId: String, region: String = "europe") async throws -> MatchDetails {
        // Convert server region to routing value for match-v5 API
        let routingRegion = getMatchRegionalEndpoint(for: region)
        let urlString = "https://\(routingRegion).api.riotgames.com/lol/match/v5/matches/\(matchId)"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(apiKey, forHTTPHeaderField: "X-Riot-Token")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                break
            case 401:
                throw APIError.unauthorizedAPIKey
            case 404:
                throw APIError.summonerNotFound
            default:
                throw APIError.requestFailed
            }
            
            let decoder = JSONDecoder()
            do {
                let matchDetails = try decoder.decode(MatchDetails.self, from: data)
                return matchDetails
            } catch {
                print("❌ Match details decoding error: \(error)")
                throw APIError.decodingFailed
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            print("❌ Match details network error: \(error)")
            throw APIError.requestFailed
        }
    }
    
    // Helper function to get the correct regional endpoint for match API
    private func getMatchRegionalEndpoint(for region: String) -> String {
        switch region.uppercased() {
        case "EUW1", "EUW", "EUNE1", "EUNE", "TR1", "TR", "RU1", "RU":
            return "europe"
        case "NA1", "BR1", "LA1", "LA2", "LAN", "LAS", "OC1", "OCE":
            return "americas"
        case "KR", "JP1":
            return "asia"
        default:
            return "europe"
        }
    }
}
