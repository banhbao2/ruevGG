import Foundation

// MARK: - Data Dragon Helper
struct DataDragonHelper {
    // Base URL for Data Dragon CDN
    static let baseURL = "https://ddragon.leagueoflegends.com/cdn"
    
    // Current version - you might want to fetch this dynamically
    // For now, using a recent stable version
    static let version = "14.23.1"
    
    // Get profile icon URL
    static func profileIconURL(for iconId: Int) -> URL? {
        let urlString = "\(baseURL)/\(version)/img/profileicon/\(iconId).png"
        return URL(string: urlString)
    }
    
    // Get champion icon URL
    static func championIconURL(for championName: String) -> URL? {
        // Champion names need special formatting for URLs
        let formattedName = formatChampionName(championName)
        let urlString = "\(baseURL)/\(version)/img/champion/\(formattedName).png"
        return URL(string: urlString)
    }
    
    // Get champion square asset URL (larger image)
    static func championSquareURL(for championName: String) -> URL? {
        let formattedName = formatChampionName(championName)
        let urlString = "https://ddragon.leagueoflegends.com/cdn/img/champion/loading/\(formattedName)_0.jpg"
        return URL(string: urlString)
    }
    
    // Format champion names for Data Dragon URLs
    private static func formatChampionName(_ name: String) -> String {
        // Handle special cases
        switch name.lowercased() {
        case "wukong":
            return "MonkeyKing"
        case "fiddlesticks":
            return "FiddleSticks"
        default:
            // Remove spaces and apostrophes, capitalize properly
            let cleaned = name
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "'", with: "")
                .replacingOccurrences(of: ".", with: "")
            
            // Special formatting for specific champions
            if cleaned.lowercased() == "aurelionsol" {
                return "AurelionSol"
            } else if cleaned.lowercased() == "drmundo" {
                return "DrMundo"
            } else if cleaned.lowercased() == "jarvaniv" {
                return "JarvanIV"
            } else if cleaned.lowercased() == "kogmaw" {
                return "KogMaw"
            } else if cleaned.lowercased() == "leesin" {
                return "LeeSin"
            } else if cleaned.lowercased() == "masteryi" {
                return "MasterYi"
            } else if cleaned.lowercased() == "missfortune" {
                return "MissFortune"
            } else if cleaned.lowercased() == "reksai" {
                return "RekSai"
            } else if cleaned.lowercased() == "tahmkench" {
                return "TahmKench"
            } else if cleaned.lowercased() == "twistedfate" {
                return "TwistedFate"
            } else if cleaned.lowercased() == "xinzhao" {
                return "XinZhao"
            }
            
            // Default: just return the cleaned name with first letter capitalized
            return cleaned.prefix(1).uppercased() + cleaned.dropFirst()
        }
    }
}

// MARK: - Async Image Loading View
import SwiftUI

struct ProfileIconView: View {
    let iconId: Int
    let size: CGFloat
    
    var body: some View {
        if let url = DataDragonHelper.profileIconURL(for: iconId) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    Circle()
                        .fill(Color(.systemGray4))
                        .frame(width: size, height: size)
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.5)
                        )
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                case .failure(let error):
                    Circle()
                        .fill(LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: size, height: size)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                                .font(.system(size: size * 0.4))
                        )
                        .onAppear {
                            print("Failed to load profile icon \(iconId): \(error)")
                        }
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            Circle()
                .fill(LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: size, height: size)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.white)
                        .font(.system(size: size * 0.4))
                )
        }
    }
}

struct ChampionIconView: View {
    let championName: String
    let size: CGFloat
    
    var body: some View {
        if let url = DataDragonHelper.championIconURL(for: championName) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    Circle()
                        .fill(Color(.systemGray4))
                        .frame(width: size, height: size)
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.5)
                        )
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                case .failure(let error):
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: size, height: size)
                        .overlay(
                            Text(String(championName.prefix(2)).uppercased())
                                .font(.system(size: size * 0.3, weight: .bold))
                                .foregroundColor(.primary)
                        )
                        .onAppear {
                            print("Failed to load champion icon for \(championName): \(error)")
                            print("URL attempted: \(url)")
                        }
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: size, height: size)
                .overlay(
                    Text(String(championName.prefix(2)).uppercased())
                        .font(.system(size: size * 0.3, weight: .bold))
                        .foregroundColor(.primary)
                )
        }
    }
}
