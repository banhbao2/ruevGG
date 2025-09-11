import SwiftUI

struct TeamResultsView: View {
    @ObservedObject var viewModel: TeamAnalysisViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMode: Int? = nil
    
    var filteredStats: (games: Int, wins: Int, losses: Int, winRate: Double) {
        guard let teamStats = viewModel.teamStats else {
            return (0, 0, 0, 0)
        }
        
        if let mode = selectedMode, let modeStats = teamStats.gamesByMode[mode] {
            return (modeStats.games, modeStats.wins, modeStats.losses, modeStats.winRate)
        } else {
            return (teamStats.gamesPlayedTogether, teamStats.wins, teamStats.losses, teamStats.winRate)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Team Analysis Results")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Target: \(viewModel.selectedGameCount) games played together")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                if !viewModel.foundPlayers.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Players Analyzed")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Text("Tap a player to view detailed stats")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        ForEach(viewModel.foundPlayers, id: \.puuid) { player in
                            if let performance = viewModel.playerPerformances[player.puuid],
                               let teamStats = viewModel.teamStats {
                                NavigationLink(destination:
                                    PlayerDetailView(
                                        player: player,
                                        performanceSummary: performance,
                                        gameModes: teamStats.sortedGameModes
                                    )
                                ) {
                                    HStack(spacing: 12) {
                                        // Use profileIconId from the player object
                                        ProfileIconView(iconId: player.profileIconId, size: 40)
                                        
                                        VStack(alignment: .leading) {
                                            Text(player.displayName)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)
                                            HStack(spacing: 8) {
                                                Text("Level \(player.level)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                
                                                if performance.totalGames > 0 {
                                                    Text("•")
                                                        .foregroundColor(.secondary)
                                                    Text(String(format: "%.1f/%.1f/%.1f",
                                                               performance.averageKills,
                                                               performance.averageDeaths,
                                                               performance.averageAssists))
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 2) {
                                            if performance.totalGames > 0 {
                                                Text(String(format: "%.0f%%", performance.winRate))
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(performance.winRate >= 50 ? .green : .red)
                                                Text("\(performance.wins)W \(performance.losses)L")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            } else {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.green)
                                            }
                                        }
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color(.tertiarySystemBackground))
                                    .cornerRadius(8)
                                    .padding(.horizontal)
                                }
                            } else {
                                HStack(spacing: 12) {
                                    ProfileIconView(iconId: player.profileIconId, size: 40)
                                    
                                    VStack(alignment: .leading) {
                                        Text(player.displayName)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text("Level \(player.level)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color(.tertiarySystemBackground))
                                .cornerRadius(8)
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                
                if let teamStats = viewModel.teamStats {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Team Performance")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if !teamStats.sortedGameModes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Game Modes")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ModeFilterButton(
                                            title: "All Modes",
                                            count: teamStats.gamesPlayedTogether,
                                            isSelected: selectedMode == nil,
                                            action: { selectedMode = nil }
                                        )
                                        
                                        ForEach(teamStats.sortedGameModes, id: \.queueId) { mode in
                                            ModeFilterButton(
                                                title: mode.modeName,
                                                count: mode.games,
                                                isSelected: selectedMode == mode.queueId,
                                                action: { selectedMode = mode.queueId }
                                            )
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        TeamResultCard(
                            teamStats: teamStats,
                            targetGames: viewModel.selectedGameCount,
                            filteredStats: filteredStats,
                            selectedModeName: selectedMode != nil ?
                                teamStats.gamesByMode[selectedMode!]?.modeName ?? "Unknown" :
                                "All Modes"
                        )
                        .padding(.horizontal)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        
                        Text("No games found")
                            .font(.headline)
                        
                        Text("These players haven't played together recently")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
                
                Button(action: { dismiss() }) {
                    Text("Back to Search")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
            }
        }
    }
}

struct ModeFilterButton: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                Text("\(count) games")
                    .font(.caption2)
                    .opacity(0.8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
        }
    }
}

struct TeamResultCard: View {
    let teamStats: TeamStats
    let targetGames: Int
    let filteredStats: (games: Int, wins: Int, losses: Int, winRate: Double)
    let selectedModeName: String
    
    var winRateColor: Color {
        if filteredStats.winRate >= 60 {
            return .green
        } else if filteredStats.winRate >= 50 {
            return .blue
        } else if filteredStats.winRate >= 40 {
            return .orange
        } else {
            return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "gamecontroller.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(selectedModeName)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    HStack(spacing: 0) {
                        Text("\(filteredStats.games)")
                            .font(.title2)
                            .fontWeight(.bold)
                        if selectedModeName == "All Modes" && filteredStats.games < targetGames {
                            Text("/\(targetGames)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    Text("Games")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 40)
                
                VStack(spacing: 4) {
                    Text(String(format: "%.0f%%", filteredStats.winRate))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(winRateColor)
                    Text("Win Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 40)
                
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Text("\(filteredStats.wins)")
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                        Text("/")
                            .foregroundColor(.secondary)
                        Text("\(filteredStats.losses)")
                            .foregroundColor(.red)
                            .fontWeight(.semibold)
                    }
                    .font(.title3)
                    Text("W / L")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(winRateColor)
                        .frame(width: geometry.size.width * (filteredStats.winRate / 100), height: 8)
                }
            }
            .frame(height: 8)
            
            if filteredStats.games == 0 {
                Text("No \(selectedModeName.lowercased()) games found")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            } else if selectedModeName == "All Modes" && filteredStats.games < targetGames {
                Text("Only found \(filteredStats.games) games together (searched last ~100 matches)")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .italic()
            }
            
            if filteredStats.games > 0 {
                HStack {
                    Image(systemName: winRateColor == .green ? "arrow.up.circle.fill" :
                                     winRateColor == .red ? "arrow.down.circle.fill" :
                                     "minus.circle.fill")
                        .foregroundColor(winRateColor)
                    
                    Text(winRateColor == .green ? "Strong performance" :
                         winRateColor == .red ? "Needs improvement" :
                         "Average performance")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
