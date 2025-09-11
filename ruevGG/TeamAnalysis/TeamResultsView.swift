import SwiftUI

struct TeamResultsView: View {
    @ObservedObject var viewModel: TeamAnalysisViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMode: Int? = nil
    @State private var animateIn = false
    
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
        ZStack {
            DesignSystem.Colors.primaryBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.md) {
                    headerSection
                    
                    if let teamStats = viewModel.teamStats {
                        teamPerformanceCard
                        
                        if !teamStats.sortedGameModes.isEmpty {
                            gameModeFilter
                        }
                        
                        playersSection
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.bottom, 100)
            }
            
            VStack {
                Spacer()
                bottomBar
            }
        }
        .navigationBarHidden(true)
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
            
            Text("TEAM ANALYSIS")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .tracking(1.2)
            
            Spacer()
            
            Color.clear
                .frame(width: 60)
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
    
    var teamPerformanceCard: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("WIN RATE")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .tracking(1.2)
                    
                    Text(String(format: "%.0f%%", filteredStats.winRate))
                        .font(.system(size: 48, weight: .black))
                        .foregroundColor(winRateColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(filteredStats.wins)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(DesignSystem.Colors.victoryGreen)
                            Text("WINS")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        
                        Text("/")
                            .font(.system(size: 20))
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(filteredStats.losses)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(DesignSystem.Colors.lossRed)
                            Text("LOSSES")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                    
                    Text("\(filteredStats.games) GAMES")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            
            WinRateBar(winRate: filteredStats.winRate)
        }
        .cardStyle()
        .scaleEffect(animateIn ? 1 : 0.9)
        .opacity(animateIn ? 1 : 0)
    }
    
    var gameModeFilter: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("GAME MODE")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .tracking(1.2)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    ModeChip(
                        title: "ALL",
                        count: viewModel.teamStats?.gamesPlayedTogether ?? 0,
                        isSelected: selectedMode == nil,
                        action: { selectedMode = nil }
                    )
                    
                    ForEach(viewModel.teamStats?.sortedGameModes ?? [], id: \.queueId) { mode in
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
        .opacity(animateIn ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.1), value: animateIn)
    }
    
    var playersSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("PLAYERS")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .tracking(1.2)
            
            ForEach(Array(viewModel.foundPlayers.enumerated()), id: \.element.puuid) { index, player in
                if let performance = viewModel.playerPerformances[player.puuid],
                   let teamStats = viewModel.teamStats {
                    NavigationLink(destination:
                        PlayerDetailView(
                            player: player,
                            performanceSummary: performance,
                            gameModes: teamStats.sortedGameModes,
                            searchedPlayers: viewModel.foundPlayers
                        )
                    ) {
                        ModernPlayerCard(player: player, performance: performance)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                            .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.1 + 0.2), value: animateIn)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    var bottomBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Text("NEW ANALYSIS")
                    .font(.system(size: 14, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(DesignSystem.Colors.primaryAccent)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(
            DesignSystem.Colors.primaryBackground
                .ignoresSafeArea()
                .shadow(color: .black.opacity(0.3), radius: 10, y: -5)
        )
    }
    
    var winRateColor: Color {
        if filteredStats.winRate >= 60 {
            return DesignSystem.Colors.victoryGreen
        } else if filteredStats.winRate >= 50 {
            return DesignSystem.Colors.primaryAccent
        } else if filteredStats.winRate >= 40 {
            return DesignSystem.Colors.amber
        } else {
            return DesignSystem.Colors.lossRed
        }
    }
}

struct WinRateBar: View {
    let winRate: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignSystem.Colors.lossRed.opacity(0.3))
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [DesignSystem.Colors.victoryGreen, DesignSystem.Colors.victoryGreen.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * (winRate / 100))
                    .animation(.spring(response: 0.5), value: winRate)
            }
        }
        .frame(height: 8)
    }
}

struct ModeChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                Text("\(count)")
                    .font(.system(size: 10, weight: .medium))
                    .opacity(0.8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected ? DesignSystem.Colors.primaryAccent : DesignSystem.Colors.darkGray
            )
            .foregroundColor(.white)
            .cornerRadius(DesignSystem.CornerRadius.small)
        }
    }
}

struct ModernPlayerCard: View {
    let player: CompletePlayer
    let performance: PlayerPerformanceSummary
    
    var kdaColor: Color {
        if performance.averageKDA >= 3 {
            return DesignSystem.Colors.victoryGreen
        } else if performance.averageKDA >= 2 {
            return DesignSystem.Colors.primaryAccent
        } else {
            return DesignSystem.Colors.amber
        }
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            ProfileIconView(iconId: player.profileIconId, size: 56)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [DesignSystem.Colors.primaryAccent, DesignSystem.Colors.primaryAccent.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(player.displayName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Label("\(player.level)", systemImage: "star.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.amber)
                    
                    Text("•")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Text(String(format: "%.2f KDA", performance.averageKDA))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(kdaColor)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.0f%%", performance.winRate))
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(performance.winRate >= 50 ? DesignSystem.Colors.victoryGreen : DesignSystem.Colors.lossRed)
                
                Text("\(performance.wins)W \(performance.losses)L")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.large)
    }
}
