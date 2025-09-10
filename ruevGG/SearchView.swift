import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = TeamAnalysisViewModel()
    @State private var showingResults = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Team Performance Analyzer")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter 2-5 summoner names to analyze team performance")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Summoner Input Fields
                VStack(spacing: 16) {
                    ForEach(0..<5) { index in
                        SummonerInputField(
                            index: index,
                            text: $viewModel.summonerInputs[index],
                            error: viewModel.inputErrors[index]
                        )
                    }
                }
                .padding(.horizontal)
                
                // Game Count Selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Games to Analyze")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Text("Number of games played together to analyze")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    HStack(spacing: 12) {
                        ForEach(viewModel.gameCountOptions, id: \.self) { count in
                            GameCountButton(
                                count: count,
                                isSelected: viewModel.selectedGameCount == count,
                                action: {
                                    viewModel.selectedGameCount = count
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 8)
                
                Spacer()
                
                // Analyze Button
                Button(action: {
                    Task {
                        await viewModel.analyzeTeam()
                        if viewModel.analysisComplete && !viewModel.hasErrors {
                            showingResults = true
                        }
                    }
                }) {
                    if viewModel.isAnalyzing {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                            Text("Analyzing...")
                                .fontWeight(.semibold)
                        }
                    } else {
                        VStack(spacing: 4) {
                            Text("Analyze Team Performance")
                                .fontWeight(.semibold)
                            Text("Last \(viewModel.selectedGameCount) games together")
                                .font(.caption)
                                .opacity(0.9)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.canAnalyze() ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(!viewModel.canAnalyze() || viewModel.isAnalyzing)
                .padding(.horizontal)
                
                // Progress indicator
                if viewModel.isAnalyzing {
                    Text(viewModel.analysisProgress)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationDestination(isPresented: $showingResults) {
                TeamResultsView(viewModel: viewModel)
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.showError = false
                }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}

// MARK: - Game Count Button Component
struct GameCountButton: View {
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(count)")
                    .font(.title3)
                    .fontWeight(isSelected ? .bold : .medium)
                Text("games")
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
        }
    }
}

// MARK: - Summoner Input Field Component
struct SummonerInputField: View {
    let index: Int
    @Binding var text: String
    let error: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Summoner \(index + 1)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if index < 2 {
                    Text("(Required)")
                        .font(.caption2)
                        .foregroundColor(.red)
                } else {
                    Text("(Optional)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if error != nil {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            TextField("Name#Tag (e.g. Faker#KR1)", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(error != nil ? Color.red : Color.clear, lineWidth: 1)
                )
            
            if let error = error {
                Text(error)
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
    }
}

#Preview {
    SearchView()
}
