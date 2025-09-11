import Foundation

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

class RiotAPIService {
    static let shared = RiotAPIService()
    
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
    
    func fetchSummoner(name: String, tag: String) async throws -> Account {
        let urlString = "https://europe.api.riotgames.com/riot/account/v1/accounts/by-riot-id/\(name)/\(tag)"
        
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
                return account
            } catch {
                throw APIError.decodingFailed
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.requestFailed
        }
    }
    
    func fetchSummonerByPUUID(_ puuid: String, region: String = "euw1") async throws -> SummonerDetails {
        let urlString = "https://\(region).api.riotgames.com/lol/summoner/v4/summoners/by-puuid/\(puuid)"
        
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
                let summonerDetails = try decoder.decode(SummonerDetails.self, from: data)
                return summonerDetails
            } catch {
                throw APIError.decodingFailed
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.requestFailed
        }
    }
    
    func fetchMatchHistory(for puuid: String, region: String = "europe", start: Int = 0, count: Int = 20) async throws -> [String] {
        let routingRegion = getMatchRegionalEndpoint(for: region)
        let urlString = "https://\(routingRegion).api.riotgames.com/lol/match/v5/matches/by-puuid/\(puuid)/ids?start=\(start)&count=\(count)"
        
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
                let matchIds = try decoder.decode([String].self, from: data)
                return matchIds
            } catch {
                throw APIError.decodingFailed
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.requestFailed
        }
    }
    
    func fetchMatchDetails(matchId: String, region: String = "europe") async throws -> MatchDetails {
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
                throw APIError.decodingFailed
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.requestFailed
        }
    }
    
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
