import Foundation
import SwiftUI

@MainActor
class TeamAnalysisViewModel: ObservableObject {
    @Published var summonerInputs: [String] = Array(repeating: "", count: 5)
    @Published var inputErrors: [String?] = Array(repeating: nil, count: 5)
    @Published var selectedGameCount: Int = 10
    let gameCountOptions = [5, 10, 15, 20]
    
    @Published var isAnalyzing = false
    @Published var analysisProgress = ""
    @Published var analysisComplete = false
    
    @Published var foundPlayers: [CompletePlayer] = []
    @Published var teamStats: TeamStats?
    @Published var playerPerformances: [String: PlayerPerformanceSummary] = [:]
    
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var hasErrors = false
    
    private let riotAPIService = RiotAPIService.shared
    private let teamAnalysisManager = TeamAnalysisManager()
    
    func canAnalyze() -> Bool {
        let validInputs = summonerInputs.filter { input in
            !input.isEmpty && input.contains("#")
        }
        return validInputs.count >= 2 && !isAnalyzing
    }
    
    func analyzeTeam() async {
        isAnalyzing = true
        analysisComplete = false
        hasErrors = false
        foundPlayers.removeAll()
        teamStats = nil
        playerPerformances.removeAll()
        inputErrors = Array(repeating: nil, count: 5)
        
        var validInputs: [(index: Int, name: String, tag: String)] = []
        
        for (index, input) in summonerInputs.enumerated() {
            if input.isEmpty {
                if index < 2 {
                    inputErrors[index] = "Required field"
                    hasErrors = true
                }
                continue
            }
            
            if let parsed = parseInput(input) {
                validInputs.append((index: index, name: parsed.name, tag: parsed.tag))
            } else {
                inputErrors[index] = "Invalid format. Use Name#Tag"
                hasErrors = true
            }
        }
        
        if validInputs.count < 2 {
            errorMessage = "Please enter at least 2 valid summoner names"
            showError = true
            isAnalyzing = false
            return
        }
        
        analysisProgress = "Finding summoners..."
        
        let players = await withTaskGroup(of: (Int, CompletePlayer?).self) { group in
            for validInput in validInputs {
                group.addTask {
                    do {
                        let account = try await self.riotAPIService.fetchSummoner(
                            name: validInput.name,
                            tag: validInput.tag
                        )
                        let summonerDetails = try await self.riotAPIService.fetchSummonerByPUUID(account.puuid)
                        return (validInput.index, CompletePlayer(account: account, summoner: summonerDetails))
                    } catch {
                        await MainActor.run {
                            self.inputErrors[validInput.index] = "Summoner not found"
                            self.hasErrors = true
                        }
                        return (validInput.index, nil)
                    }
                }
            }
            
            var results: [(Int, CompletePlayer)] = []
            for await (index, player) in group {
                if let player = player {
                    results.append((index, player))
                }
            }
            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
        
        foundPlayers = players
        
        if foundPlayers.count < 2 {
            errorMessage = "Could not find at least 2 valid summoners. Please check the names and try again."
            showError = true
            isAnalyzing = false
            return
        }
        
        analysisProgress = "Analyzing last \(selectedGameCount) games played together..."
        teamAnalysisManager.targetGamesCount = selectedGameCount
        
        await teamAnalysisManager.analyzeTeamPerformance(players: foundPlayers)
        
        teamStats = teamAnalysisManager.teamStats
        playerPerformances = teamAnalysisManager.playerPerformances
        
        analysisComplete = true
        isAnalyzing = false
        analysisProgress = ""
        
        if !teamAnalysisManager.errorMessage.isEmpty {
            errorMessage = teamAnalysisManager.errorMessage
            showError = true
        }
    }
    
    private func parseInput(_ input: String) -> (name: String, tag: String)? {
        let components = input.split(separator: "#", maxSplits: 1)
        guard components.count == 2 else { return nil }
        
        let name = String(components[0]).trimmingCharacters(in: .whitespacesAndNewlines)
        let tag = String(components[1]).trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        guard !name.isEmpty && !tag.isEmpty else { return nil }
        return (name: name, tag: tag)
    }
    
    func reset() {
        summonerInputs = Array(repeating: "", count: 5)
        inputErrors = Array(repeating: nil, count: 5)
        foundPlayers.removeAll()
        teamStats = nil
        playerPerformances.removeAll()
        analysisComplete = false
        hasErrors = false
        errorMessage = ""
        selectedGameCount = 10
    }
}
