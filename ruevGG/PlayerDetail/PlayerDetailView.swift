import SwiftUI

struct PlayerDetailView: View {
    let player: CompletePlayer
    let performanceSummary: PlayerPerformanceSummary
    let gameModes: [GameModeStats]
    
    @State private var selectedMode: Int? = nil
    @State private var showingMatchHistory = false
    @Environment(\.dismiss) private var dismiss
    
    var filteredSummary: PlayerPerformanceSummary {
        performanceSummary.filteredByGameMode(selectedMode)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                PlayerHeaderCard(player: player)
                
                if !gameModes.isEmpty {
                    GameModeFilterSection(
                        gameModes: gameModes,
                        selectedMode: $selectedMode,
                        totalGames: performanceSummary.totalGames
                    )
                }
                
                PerformanceOverviewCard(summary: filteredSummary)
                KDADashboard(summary: filteredSummary)
                
                if !filteredSummary.championStats.isEmpty {
                    ChampionPoolSection(champions: filteredSummary.championStats)
                }
                
                if !filteredSummary.positionStats.isEmpty {
                    PositionStatsSection(positions: filteredSummary.positionStats)
                }
                
                GameEconomyCard(summary: filteredSummary)
                CombatStatsCard(summary: filteredSummary)
                NotableGamesSection(summary: filteredSummary)
                
                Button(action: { showingMatchHistory = true }) {
                    HStack {
                        Image(systemName: "list.bullet")
                        Text("View Match History")
                        Image(systemName: "chevron.right")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("\(player.account.gameName)'s Stats")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingMatchHistory) {
            MatchHistoryView(
                matches: filteredSummary.matches,
                playerName: player.displayName
            )
        }
    }
}

struct PlayerHeaderCard: View {
    let player: CompletePlayer
    
    var body: some View {
        HStack(spacing: 16) {
            // Load actual summoner icon from Riot CDN
            ProfileIconView(iconId: player.summoner.profileIconId, size: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(player.displayName)
                    .font(.title3)
                    .fontWeight(.bold)
                
                HStack {
                    Label("Level \(player.level)", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct GameModeFilterSection: View {
    let gameModes: [GameModeStats]
    @Binding var selectedMode: Int?
    let totalGames: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Filter by Game Mode")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "All Modes",
                        count: totalGames,
                        isSelected: selectedMode == nil
                    ) {
                        selectedMode = nil
                    }
                    
                    ForEach(gameModes, id: \.queueId) { mode in
                        FilterChip(
                            title: mode.modeName,
                            count: mode.games,
                            isSelected: selectedMode == mode.queueId
                        ) {
                            selectedMode = mode.queueId
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                Text("\(count)")
                    .font(.caption2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

struct PerformanceOverviewCard: View {
    let summary: PlayerPerformanceSummary
    
    var winRateColor: Color {
        if summary.winRate >= 60 { return .green }
        else if summary.winRate >= 50 { return .blue }
        else if summary.winRate >= 40 { return .orange }
        else { return .red }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Performance Overview")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 0) {
                StatBox(
                    value: "\(summary.totalGames)",
                    label: "Games",
                    color: .primary
                )
                
                Divider()
                    .frame(height: 50)
                
                StatBox(
                    value: String(format: "%.0f%%", summary.winRate),
                    label: "Win Rate",
                    color: winRateColor
                )
                
                Divider()
                    .frame(height: 50)
                
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Text("\(summary.wins)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("-")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("\(summary.losses)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                    Text("W - L")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(winRateColor)
                        .frame(width: geometry.size.width * (summary.winRate / 100))
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct StatBox: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct KDADashboard: View {
    let summary: PlayerPerformanceSummary
    
    var kdaColor: Color {
        if summary.averageKDA >= 5 { return .purple }
        else if summary.averageKDA >= 3 { return .green }
        else if summary.averageKDA >= 2 { return .blue }
        else { return .orange }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("KDA Statistics")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                Text(String(format: "%.2f", summary.averageKDA))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(kdaColor)
                
                Text("Average KDA")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", summary.averageKills))
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Kills")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("/")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", summary.averageDeaths))
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Deaths")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("/")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", summary.averageAssists))
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Assists")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(spacing: 8) {
                HStack {
                    Label("\(summary.totalKills) total kills", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Spacer()
                    
                    Label("\(summary.totalDeaths) total deaths", systemImage: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                HStack {
                    Label("\(summary.totalAssists) total assists", systemImage: "hand.raised.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct ChampionPoolSection: View {
    let champions: [ChampionPerformance]
    @State private var showAll = false
    
    var displayedChampions: [ChampionPerformance] {
        showAll ? champions : Array(champions.prefix(3))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Champion Pool")
                    .font(.headline)
                
                Spacer()
                
                if champions.count > 3 {
                    Button(action: { showAll.toggle() }) {
                        Text(showAll ? "Show Less" : "Show All (\(champions.count))")
                            .font(.caption)
                    }
                }
            }
            .padding(.horizontal)
            
            VStack(spacing: 8) {
                ForEach(displayedChampions) { champion in
                    ChampionRow(champion: champion)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct ChampionRow: View {
    let champion: ChampionPerformance
    
    var winRateColor: Color {
        if champion.winRate >= 60 { return .green }
        else if champion.winRate >= 50 { return .blue }
        else { return .orange }
    }
    
    var body: some View {
        HStack {
            // Load actual champion icon
            ChampionIconView(championName: champion.championName, size: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(champion.championName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(champion.kdaString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.0f%%", champion.winRate))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(winRateColor)
                
                Text("\(champion.gamesPlayed) games")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
    }
}

struct PositionStatsSection: View {
    let positions: [PositionPerformance]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Position Performance")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(positions) { position in
                        PositionCard(position: position)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct PositionCard: View {
    let position: PositionPerformance
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: position.icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(position.displayName)
                .font(.caption)
                .fontWeight(.medium)
            
            Text("\(position.gamesPlayed)")
                .font(.title3)
                .fontWeight(.bold)
            
            Text("games")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(String(format: "%.0f%%", position.winRate))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(position.winRate >= 50 ? .green : .red)
        }
        .frame(width: 80)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct GameEconomyCard: View {
    let summary: PlayerPerformanceSummary
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Game Economy")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "circle.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        Text(String(format: "%.0f", summary.averageGold))
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    Text("Avg Gold")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 30)
                
                VStack(spacing: 4) {
                    Text(String(format: "%.0f", summary.averageGoldPerMinute))
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Gold/min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 30)
                
                VStack(spacing: 4) {
                    Text(String(format: "%.0f", summary.averageCS))
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Avg CS")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 30)
                
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", summary.averageCSPerMinute))
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("CS/min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct CombatStatsCard: View {
    let summary: PlayerPerformanceSummary
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Combat Statistics")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                HStack {
                    Label("Damage Dealt", systemImage: "bolt.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Spacer()
                    
                    Text(formatNumber(summary.averageDamageDealt))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Label("Damage Taken", systemImage: "shield.fill")
                        .font(.caption)
                        .foregroundColor(.purple)
                    
                    Spacer()
                    
                    Text(formatNumber(summary.averageDamageTaken))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Label("Vision Score", systemImage: "eye.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text(String(format: "%.0f", summary.averageVisionScore))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    func formatNumber(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "%.1fk", value / 1000)
        }
        return String(format: "%.0f", value)
    }
}

struct NotableGamesSection: View {
    let summary: PlayerPerformanceSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notable Games")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                if let bestGame = summary.bestKDAGame {
                    NotableGameRow(
                        title: "Best KDA",
                        match: bestGame,
                        icon: "star.fill",
                        iconColor: .yellow
                    )
                }
                
                if let highestKills = summary.highestKillGame {
                    NotableGameRow(
                        title: "Most Kills",
                        match: highestKills,
                        icon: "flame.fill",
                        iconColor: .orange
                    )
                }
                
                if let highestCS = summary.highestCSGame {
                    NotableGameRow(
                        title: "Highest CS",
                        match: highestCS,
                        icon: "circle.grid.3x3.fill",
                        iconColor: .green
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

struct NotableGameRow: View {
    let title: String
    let match: PlayerMatchData
    let icon: String
    let iconColor: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(match.championName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(match.kdaString)
                        .font(.subheadline)
                }
            }
            
            Spacer()
            
            Text(match.win ? "Victory" : "Defeat")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(match.win ? .green : .red)
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
    }
}
