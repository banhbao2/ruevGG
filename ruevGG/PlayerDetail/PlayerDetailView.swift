import SwiftUI

struct PlayerDetailView: View {
    let player: CompletePlayer
    let performanceSummary: PlayerPerformanceSummary
    let gameModes: [GameModeStats]
    var searchedPlayers: [CompletePlayer] = [] // Add this parameter
    
    @State private var selectedMode: Int? = nil
    @State private var showingMatchHistory = false
    @State private var animateIn = false
    @Environment(\.dismiss) private var dismiss
    
    var filteredSummary: PlayerPerformanceSummary {
        performanceSummary.filteredByGameMode(selectedMode)
    }
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.primaryBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.md) {
                    headerSection
                    playerHeaderCard
                    statsGrid
                    championSection
                    matchHistoryButton
                }
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.bottom, DesignSystem.Spacing.xl)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingMatchHistory) {
            MatchHistoryView(
                matches: filteredSummary.matches,
                playerName: player.displayName,
                searchedPlayers: searchedPlayers.isEmpty ? [player] : searchedPlayers
            )
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animateIn = true
            }
        }
    }
    
    var headerSection: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                    Text("BACK")
                        .font(.system(size: 14, weight: .bold))
                        .tracking(1.2)
                }
                .foregroundColor(DesignSystem.Colors.primaryAccent)
            }
            
            Spacer()
            
            Text("PLAYER STATS")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .tracking(1.2)
            
            Spacer()
            
            Color.clear
                .frame(width: 60)
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
    
    var playerHeaderCard: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.md) {
                ProfileIconView(iconId: player.profileIconId, size: 80)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [DesignSystem.Colors.primaryAccent, DesignSystem.Colors.primaryAccent.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                    )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(player.displayName)
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(.white)
                    
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        StatBadge(
                            icon: "star.fill",
                            value: "Level \(player.level)",
                            color: DesignSystem.Colors.amber
                        )
                        
                        StatBadge(
                            icon: "gamecontroller.fill",
                            value: "\(filteredSummary.totalGames) Games",
                            color: DesignSystem.Colors.primaryAccent
                        )
                    }
                }
                
                Spacer()
            }
            
            if !gameModes.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ModeChip(
                            title: "ALL",
                            count: performanceSummary.totalGames,
                            isSelected: selectedMode == nil,
                            action: { selectedMode = nil }
                        )
                        
                        ForEach(gameModes, id: \.queueId) { mode in
                            ModeChip(
                                title: mode.modeName.uppercased(),
                                count: mode.games,
                                isSelected: selectedMode == mode.queueId,
                                action: { selectedMode = mode.queueId }
                            )
                        }
                    }
                }
            }
        }
        .cardStyle()
        .scaleEffect(animateIn ? 1 : 0.9)
        .opacity(animateIn ? 1 : 0)
    }
    
    var statsGrid: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                StatCard(
                    title: "WIN RATE",
                    value: String(format: "%.0f%%", filteredSummary.winRate),
                    subtitle: "\(filteredSummary.wins)W - \(filteredSummary.losses)L",
                    color: filteredSummary.winRate >= 50 ? DesignSystem.Colors.victoryGreen : DesignSystem.Colors.lossRed
                )
                
                StatCard(
                    title: "KDA",
                    value: String(format: "%.2f", filteredSummary.averageKDA),
                    subtitle: String(format: "%.1f/%.1f/%.1f",
                                   filteredSummary.averageKills,
                                   filteredSummary.averageDeaths,
                                   filteredSummary.averageAssists),
                    color: kdaColor
                )
            }
            
            HStack(spacing: DesignSystem.Spacing.sm) {
                StatCard(
                    title: "CS/MIN",
                    value: String(format: "%.1f", filteredSummary.averageCSPerMinute),
                    subtitle: String(format: "%.0f total", filteredSummary.averageCS),
                    color: DesignSystem.Colors.primaryAccent
                )
                
                StatCard(
                    title: "GOLD/MIN",
                    value: String(format: "%.0f", filteredSummary.averageGoldPerMinute),
                    subtitle: String(format: "%.0fk avg", filteredSummary.averageGold / 1000),
                    color: DesignSystem.Colors.amber
                )
            }
        }
        .opacity(animateIn ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.1), value: animateIn)
    }
    
    var championSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("TOP CHAMPIONS")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .tracking(1.2)
            
            ForEach(Array(filteredSummary.championStats.prefix(3).enumerated()), id: \.element.id) { index, champion in
                ChampionStatRow(champion: champion)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)
                    .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.1 + 0.2), value: animateIn)
            }
        }
    }
    
    var matchHistoryButton: some View {
        Button(action: { showingMatchHistory = true }) {
            HStack {
                Image(systemName: "list.bullet.rectangle")
                Text("VIEW MATCH HISTORY")
                    .font(.system(size: 14, weight: .bold))
                    .tracking(1.2)
                Image(systemName: "chevron.right")
            }
        }
        .primaryButtonStyle()
        .opacity(animateIn ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.3), value: animateIn)
    }
    
    var kdaColor: Color {
        if filteredSummary.averageKDA >= 3 {
            return DesignSystem.Colors.victoryGreen
        } else if filteredSummary.averageKDA >= 2 {
            return DesignSystem.Colors.primaryAccent
        } else {
            return DesignSystem.Colors.amber
        }
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(value)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.2))
        .cornerRadius(6)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .tracking(1.2)
            
            Text(value)
                .font(.system(size: 28, weight: .black))
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.medium)
    }
}

struct ChampionStatRow: View {
    let champion: ChampionPerformance
    
    var winRateColor: Color {
        if champion.winRate >= 60 {
            return DesignSystem.Colors.victoryGreen
        } else if champion.winRate >= 50 {
            return DesignSystem.Colors.primaryAccent
        } else {
            return DesignSystem.Colors.amber
        }
    }
    
    var body: some View {
        HStack {
            ChampionIconView(championName: champion.championName, size: 48)
                .overlay(
                    Circle()
                        .stroke(winRateColor.opacity(0.5), lineWidth: 2)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(champion.championName.uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                Text(champion.kdaString)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.0f%%", champion.winRate))
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(winRateColor)
                
                Text("\(champion.gamesPlayed) games")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.medium)
    }
}
