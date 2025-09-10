import Foundation
import SwiftUI

@MainActor
class TeamAnalysisViewModel: ObservableObject {
    // Input Management
    @Published var summonerInputs: [String] = Array(repeating: "", count: 5)
    @Published var inputErrors: [String?] = Array(repeating: nil, count: 5)
    
    // Game count selection
    @Published var selectedGameCount: Int = 10
    let gameCountOptions = [5, 10, 15, 20]
    
    // Analysis State
    @Published var isAnalyzing = false
    @Published var analysisProgress = ""
    @Published var analysisComplete = false
    
    // Results
    @Published var foundPlayers: [CompletePlayer] = []
    @Published var teamStats: TeamStats?
    
    // Error Handling
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var hasErrors = false
    
    private let riotAPIService = RiotAPIService.shared
    private let teamAnalysisManager = TeamAnalysisManager()
    
    // MARK: - Public Methods
    
    func canAnalyze() -> Bool {
        // Need at least 2 valid inputs to analyze
        let validInputs = summonerInputs.filter { input in
            !input.isEmpty && input.contains("#")
        }
        return validInputs.count >= 2 && !isAnalyzing
    }
    
    func analyzeTeam() async {
        // Reset state
        isAnalyzing = true
        analysisComplete = false
        hasErrors = false
        foundPlayers.removeAll()
        teamStats = nil
        inputErrors = Array(repeating: nil, count: 5)
        
        // Parse and validate inputs
        var validInputs: [(index: Int, name: String, tag: String)] = []
        
        for (index, input) in summonerInputs.enumerated() {
            // Skip empty inputs for optional fields
            if input.isEmpty {
                if index < 2 {
                    // First two are required
                    inputErrors[index] = "Required field"
                    hasErrors = true
                }
                continue
            }
            
            // Parse the input
            if let parsed = parseInput(input) {
                validInputs.append((index: index, name: parsed.name, tag: parsed.tag))
            } else {
                inputErrors[index] = "Invalid format. Use Name#Tag"
                hasErrors = true
            }
        }
        
        // Check if we have at least 2 valid inputs
        if validInputs.count < 2 {
            errorMessage = "Please enter at least 2 valid summoner names"
            showError = true
            isAnalyzing = false
            return
        }
        
        // Search for each player
        analysisProgress = "Finding summoners..."
        
        for validInput in validInputs {
            analysisProgress = "Searching for \(validInput.name)#\(validInput.tag)..."
            
            do {
                let account = try await riotAPIService.fetchSummoner(
                    name: validInput.name,
                    tag: validInput.tag
                )
                
                let summonerDetails = try await riotAPIService.fetchSummonerByPUUID(account.puuid)
                
                let player = CompletePlayer(account: account, summoner: summonerDetails)
                foundPlayers.append(player)
                
                // Add delay to avoid rate limiting
                try? await Task.sleep(nanoseconds: 1_200_000_000) // 1.2 seconds
                
            } catch {
                inputErrors[validInput.index] = "Summoner not found"
                hasErrors = true
                print("Failed to find \(validInput.name)#\(validInput.tag): \(error)")
            }
        }
        
        // Check if we found at least 2 players
        if foundPlayers.count < 2 {
            errorMessage = "Could not find at least 2 valid summoners. Please check the names and try again."
            showError = true
            isAnalyzing = false
            return
        }
        
        // Analyze team performance with selected game count
        analysisProgress = "Analyzing last \(selectedGameCount) games played together..."
        
        // Create a custom analysis manager with selected games limit
        teamAnalysisManager.targetGamesCount = selectedGameCount
        
        await teamAnalysisManager.analyzeTeamPerformance(players: foundPlayers)
        
        // Store results
        teamStats = teamAnalysisManager.teamStats
        
        // Update state
        analysisComplete = true
        isAnalyzing = false
        analysisProgress = ""
        
        // Show error if there was an issue during analysis
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
        analysisComplete = false
        hasErrors = false
        errorMessage = ""
        selectedGameCount = 10 // Reset to default
    }
}
