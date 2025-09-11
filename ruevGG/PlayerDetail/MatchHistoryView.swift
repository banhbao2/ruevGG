import SwiftUI

struct MatchHistoryView: View {
    let matches: [PlayerMatchData]
    let playerName: String
    @Environment(\.dismiss) private var dismiss
    
    var sortedMatches: [PlayerMatchData] {
        matches.sorted { $0.gameCreation > $1.gameCreation }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    // Summary Header
                    MatchHistorySummary(matches: matches)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    // Match List
                    ForEach(sortedMatches) { match in
                        MatchRow(match: match)
                            .padding(.horizontal)
                    }
                    
                    if matches.isEmpty {
                        EmptyStateView()
                            .padding(.top, 50)
                    }
                }
                .padding(.bottom)
            }
            .navigationTitle("Match History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Match History Summary
struct MatchHistorySummary: View {
    let matches: [PlayerMatchData]
    
    var wins: Int { matches.filter { $0.win }.count }
    var losses: Int { matches.count - wins }
    var winRate: Double {
        matches.count > 0 ? (Double(wins) / Double(matches.count)) * 100 : 0
    }
    
    var body: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("\(matches.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Total Games")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .frame(height: 40)
            
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text("\(wins)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    Text("-")
                        .foregroundColor(.secondary)
                    Text("\(losses)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
                Text("Record")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .frame(height: 40)
            
            VStack(spacing: 4) {
                Text(String(format: "%.0f%%", winRate))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(winRate >= 50 ? .green : .red)
                Text("Win Rate")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Match Row
struct MatchRow: View {
    let match: PlayerMatchData
    
    var kdaColor: Color {
        if match.kda >= 5 { return .purple }
        else if match.kda >= 3 { return .green }
        else if match.kda >= 2 { return .blue }
        else if match.kda >= 1 { return .orange }
        else { return .red }
    }
    
    var resultColor: Color {
        match.win ? Color.green.opacity(0.1) : Color.red.opacity(0.1)
    }
    
    var resultBorderColor: Color {
        match.win ? Color.green : Color.red
    }
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Result Indicator
            VStack {
                Text(match.win ? "W" : "L")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(match.win ? .green : .red)
                
                Text(match.gameDurationFormatted)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 40)
            
            // Champion & Stats
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    // Champion Icon
                    ChampionIconView(championName: match.championName, size: 32)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(match.championName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(match.modeName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Position
                    if !match.teamPosition.isEmpty {
                        PositionBadge(position: match.teamPosition)
                    }
                }
                
                // KDA and Stats
                HStack(spacing: 16) {
                    // KDA
                    VStack(alignment: .leading, spacing: 2) {
                        Text(match.kdaString)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 4) {
                            Text(String(format: "%.2f", match.kda))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(kdaColor)
                            Text("KDA")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // CS
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(match.totalCS)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack(spacing: 4) {
                            Text(String(format: "%.1f", match.csPerMinute))
                                .font(.caption)
                            Text("CS/min")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Gold
                    VStack(alignment: .leading, spacing: 2) {
                        Text(formatGold(match.goldEarned))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Gold")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Vision
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(match.visionScore)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Vision")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Additional Stats
                HStack(spacing: 12) {
                    Label("\(formatDamage(match.totalDamageDealt)) dmg", systemImage: "bolt.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Label("\(formatDamage(match.totalDamageTaken)) taken", systemImage: "shield.fill")
                        .font(.caption)
                        .foregroundColor(.purple)
                    
                    Spacer()
                    
                    Text(dateFormatter.string(from: match.gameCreation))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .padding()
        .background(resultColor)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(resultBorderColor.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }
    
    func formatGold(_ gold: Int) -> String {
        if gold >= 1000 {
            return String(format: "%.1fk", Double(gold) / 1000)
        }
        return "\(gold)"
    }
    
    func formatDamage(_ damage: Int) -> String {
        if damage >= 1000 {
            return String(format: "%.1fk", Double(damage) / 1000)
        }
        return "\(damage)"
    }
}

// MARK: - Position Badge
struct PositionBadge: View {
    let position: String
    
    var displayName: String {
        switch position.uppercased() {
        case "TOP": return "TOP"
        case "JUNGLE": return "JGL"
        case "MIDDLE": return "MID"
        case "BOTTOM": return "ADC"
        case "UTILITY": return "SUP"
        default: return "FILL"
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
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray5))
        .cornerRadius(6)
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Matches Found")
                .font(.headline)
            
            Text("No matches to display with current filters")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
