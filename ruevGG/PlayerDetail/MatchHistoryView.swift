import SwiftUI

struct MatchHistoryView: View {
    let matches: [PlayerMatchData]
    let playerName: String
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMode: Int? = nil
    @State private var expandedMatchId: String? = nil
    @State private var matchParticipants: [String: [MatchParticipant]] = [:]
    @State private var animateIn = false
    
    var gameModes: [GameModeStats] {
        let grouped = Dictionary(grouping: matches, by: { $0.queueId })
        return grouped.map { (queueId, matches) in
            GameModeStats(
                modeName: GameModeHelper.getModeName(for: queueId),
                queueId: queueId,
                games: matches.count,
                wins: matches.filter { $0.win }.count,
                losses: matches.filter { !$0.win }.count
            )
        }.sorted { $0.games > $1.games }
    }
    
    var filteredMatches: [PlayerMatchData] {
        if let mode = selectedMode {
            return matches.filter { $0.queueId == mode }.sorted { $0.gameCreation > $1.gameCreation }
        }
        return matches.sorted { $0.gameCreation > $1.gameCreation }
    }
    
    var filteredStats: (games: Int, wins: Int, losses: Int, winRate: Double) {
        let filtered = filteredMatches
        let wins = filtered.filter { $0.win }.count
        let losses = filtered.count - wins
        let winRate = filtered.count > 0 ? (Double(wins) / Double(filtered.count)) * 100 : 0
        return (filtered.count, wins, losses, winRate)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                DesignSystem.Colors.primaryBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerSection
                    
                    ScrollView {
                        VStack(spacing: DesignSystem.Spacing.md) {
                            summaryCard
                            
                            if !gameModes.isEmpty {
                                gameModeFilter
                            }
                            
                            matchList
                        }
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.bottom, DesignSystem.Spacing.xl)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    animateIn = true
                }
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
            
            Text("MATCH HISTORY")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .tracking(1.2)
            
            Spacer()
            
            Button("Done") {
                dismiss()
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(DesignSystem.Colors.primaryAccent)
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.primaryBackground)
    }
    
    var summaryCard: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            VStack(spacing: 4) {
                Text("\(filteredStats.games)")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.white)
                Text("Total Games")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text("\(filteredStats.wins)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.victoryGreen)
                    Text("-")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    Text("\(filteredStats.losses)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.lossRed)
                }
                Text("Record")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            
            VStack(spacing: 4) {
                Text(String(format: "%.0f%%", filteredStats.winRate))
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(filteredStats.winRate >= 50 ? DesignSystem.Colors.victoryGreen : DesignSystem.Colors.lossRed)
                Text("Win Rate")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
        .scaleEffect(animateIn ? 1 : 0.9)
        .opacity(animateIn ? 1 : 0)
    }
    
    var gameModeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ModeChip(
                    title: "ALL",
                    count: matches.count,
                    isSelected: selectedMode == nil,
                    action: {
                        withAnimation(.spring(response: 0.3)) {
                            selectedMode = nil
                        }
                    }
                )
                
                ForEach(gameModes, id: \.queueId) { mode in
                    ModeChip(
                        title: mode.modeName.uppercased(),
                        count: mode.games,
                        isSelected: selectedMode == mode.queueId,
                        action: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedMode = mode.queueId
                            }
                        }
                    )
                }
            }
        }
        .opacity(animateIn ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.1), value: animateIn)
    }
    
    var matchList: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            if filteredMatches.isEmpty {
                emptyState
            } else {
                ForEach(Array(filteredMatches.enumerated()), id: \.element.id) { index, match in
                    VStack(spacing: 0) {
                        MatchRowCard(
                            match: match,
                            isExpanded: expandedMatchId == match.matchId,
                            onTap: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    if expandedMatchId == match.matchId {
                                        expandedMatchId = nil
                                    } else {
                                        expandedMatchId = match.matchId
                                        loadMatchParticipants(for: match.matchId)
                                    }
                                }
                            }
                        )
                        
                        if expandedMatchId == match.matchId {
                            MatchParticipantsView(
                                participants: matchParticipants[match.matchId] ?? [],
                                currentPlayerPuuid: nil
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            ))
                        }
                    }
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)
                    .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.05 + 0.2), value: animateIn)
                }
            }
        }
    }
    
    var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            Text("No Matches Found")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text("No matches to display with current filters")
                .font(.system(size: 14))
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, DesignSystem.Spacing.xl)
    }
    
    func loadMatchParticipants(for matchId: String) {
        Task {
            do {
                let details = try await RiotAPIService.shared.fetchMatchDetails(matchId: matchId)
                let participants = details.info.participants.map { participant in
                    MatchParticipant(
                        championName: participant.championName,
                        kills: participant.kills,
                        deaths: participant.deaths,
                        assists: participant.assists,
                        teamId: participant.teamId,
                        win: participant.win,
                        position: participant.individualPosition
                    )
                }
                
                await MainActor.run {
                    withAnimation {
                        matchParticipants[matchId] = participants
                    }
                }
            } catch {
                print("Failed to load match participants: \(error)")
            }
        }
    }
}

struct MatchRowCard: View {
    let match: PlayerMatchData
    let isExpanded: Bool
    let onTap: () -> Void
    
    var kdaColor: Color {
        if match.kda >= 5 { return DesignSystem.Colors.victoryGreen }
        else if match.kda >= 3 { return DesignSystem.Colors.primaryAccent }
        else if match.kda >= 2 { return DesignSystem.Colors.amber }
        else { return DesignSystem.Colors.lossRed }
    }
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy, HH:mm"
        return formatter
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    // Win/Loss indicator
                    VStack(spacing: 4) {
                        Text(match.win ? "W" : "L")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(match.win ? DesignSystem.Colors.victoryGreen : DesignSystem.Colors.lossRed)
                        
                        Text(match.gameDurationFormatted)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    .frame(width: 40)
                    
                    // Champion icon
                    ChampionIconView(championName: match.championName, size: 48)
                        .overlay(
                            Circle()
                                .stroke(match.win ? DesignSystem.Colors.victoryGreen.opacity(0.5) : DesignSystem.Colors.lossRed.opacity(0.5), lineWidth: 2)
                        )
                    
                    // Champion and mode info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(match.championName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(match.modeName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Position
                    if !match.teamPosition.isEmpty {
                        PositionIcon(position: match.teamPosition)
                    }
                    
                    // Expand indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(DesignSystem.Spacing.sm)
                
                // Stats row
                HStack(spacing: DesignSystem.Spacing.md) {
                    StatItem(
                        value: match.kdaString,
                        label: String(format: "%.2f KDA", match.kda),
                        color: kdaColor
                    )
                    
                    StatItem(
                        value: "\(match.totalCS)",
                        label: String(format: "%.1f CS/min", match.csPerMinute),
                        color: .white
                    )
                    
                    StatItem(
                        value: formatGold(match.goldEarned),
                        label: "Gold",
                        color: DesignSystem.Colors.amber
                    )
                    
                    StatItem(
                        value: "\(match.visionScore)",
                        label: "Vision",
                        color: .white
                    )
                }
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.bottom, DesignSystem.Spacing.sm)
                
                // Damage and date row
                HStack {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Label(formatDamage(match.totalDamageDealt) + " dmg", systemImage: "bolt.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.amber)
                        
                        Label(formatDamage(match.totalDamageTaken) + " taken", systemImage: "shield.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.primaryAccent)
                    }
                    
                    Spacer()
                    
                    Text(dateFormatter.string(from: match.gameCreation))
                        .font(.system(size: 11))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.bottom, DesignSystem.Spacing.sm)
            }
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .fill(DesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                            .stroke(
                                match.win ? DesignSystem.Colors.victoryGreen.opacity(0.3) : DesignSystem.Colors.lossRed.opacity(0.3),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
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

struct StatItem: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PositionIcon: View {
    let position: String
    
    var displayName: String {
        switch position.uppercased() {
        case "TOP": return "TOP"
        case "JUNGLE": return "JGL"
        case "MIDDLE": return "MID"
        case "BOTTOM": return "ADC"
        case "UTILITY": return "SUP"
        default: return ""
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
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 14))
            Text(displayName)
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundColor(DesignSystem.Colors.primaryAccent)
    }
}

struct MatchParticipantsView: View {
    let participants: [MatchParticipant]
    let currentPlayerPuuid: String?
    
    var team1: [MatchParticipant] {
        participants.filter { $0.teamId == 100 }.sorted { sortByPosition($0.position) < sortByPosition($1.position) }
    }
    
    var team2: [MatchParticipant] {
        participants.filter { $0.teamId == 200 }.sorted { sortByPosition($0.position) < sortByPosition($1.position) }
    }
    
    func sortByPosition(_ position: String) -> Int {
        switch position.uppercased() {
        case "TOP": return 0
        case "JUNGLE": return 1
        case "MIDDLE": return 2
        case "BOTTOM": return 3
        case "UTILITY": return 4
        default: return 5
        }
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            if !team1.isEmpty {
                TeamSection(
                    teamName: "BLUE TEAM",
                    participants: team1,
                    teamColor: Color.blue,
                    won: team1.first?.win ?? false
                )
            }
            
            if !team2.isEmpty {
                TeamSection(
                    teamName: "RED TEAM",
                    participants: team2,
                    teamColor: Color.red,
                    won: team2.first?.win ?? false
                )
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.darkGray)
        .cornerRadius(DesignSystem.CornerRadius.medium)
    }
}

struct TeamSection: View {
    let teamName: String
    let participants: [MatchParticipant]
    let teamColor: Color
    let won: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Text(teamName)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(teamColor)
                    .tracking(1.2)
                
                if won {
                    Text("VICTORY")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.victoryGreen)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(DesignSystem.Colors.victoryGreen.opacity(0.2))
                        .cornerRadius(4)
                }
                
                Spacer()
            }
            
            ForEach(participants, id: \.championName) { participant in
                ParticipantRow(participant: participant)
            }
        }
    }
}

struct ParticipantRow: View {
    let participant: MatchParticipant
    
    var kdaColor: Color {
        let kda = Double(participant.kills + participant.assists) / Double(max(participant.deaths, 1))
        if kda >= 5 { return DesignSystem.Colors.victoryGreen }
        else if kda >= 3 { return DesignSystem.Colors.primaryAccent }
        else if kda >= 2 { return DesignSystem.Colors.amber }
        else { return DesignSystem.Colors.lossRed }
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            ChampionIconView(championName: participant.championName, size: 24)
            
            Text(participant.championName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            Text("\(participant.kills)/\(participant.deaths)/\(participant.assists)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(kdaColor)
            
            let kda = Double(participant.kills + participant.assists) / Double(max(participant.deaths, 1))
            Text(String(format: "%.2f", kda))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .frame(width: 35, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
}

struct MatchParticipant {
    let championName: String
    let kills: Int
    let deaths: Int
    let assists: Int
    let teamId: Int
    let win: Bool
    let position: String
}
