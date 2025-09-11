import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = TeamAnalysisViewModel()
    @State private var showingResults = false
    @State private var animateIn = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.primaryBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        headerSection
                        summonerInputSection
                        gameCountSection
                        analyzeButton
                    }
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.top, DesignSystem.Spacing.md)
                }
            }
            .navigationBarHidden(true)
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
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    animateIn = true
                }
            }
        }
    }
    
    var headerSection: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            HStack {
                Image(systemName: "gamecontroller.fill")
                    .font(.largeTitle)
                    .foregroundColor(DesignSystem.Colors.primaryAccent)
                
                Text("RUEVGG")
                    .font(.system(size: 32, weight: .black, design: .default))
                    .foregroundColor(.white)
            }
            .scaleEffect(animateIn ? 1 : 0.8)
            .opacity(animateIn ? 1 : 0)
            
            Text("Team Performance Analyzer")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .opacity(animateIn ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.1), value: animateIn)
        }
        .padding(.vertical, DesignSystem.Spacing.md)
    }
    
    var summonerInputSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("SUMMONERS")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .tracking(1.2)
            
            VStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(0..<5) { index in
                    ModernInputField(
                        index: index,
                        text: $viewModel.summonerInputs[index],
                        error: viewModel.inputErrors[index]
                    )
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)
                    .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.05), value: animateIn)
                }
            }
        }
    }
    
    var gameCountSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("GAMES TO ANALYZE")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .tracking(1.2)
            
            HStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(viewModel.gameCountOptions, id: \.self) { count in
                    GameCountChip(
                        count: count,
                        isSelected: viewModel.selectedGameCount == count,
                        action: {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.selectedGameCount = count
                            }
                        }
                    )
                }
            }
        }
        .opacity(animateIn ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.3), value: animateIn)
    }
    
    var analyzeButton: some View {
        Button(action: {
            Task {
                await viewModel.analyzeTeam()
                if viewModel.analysisComplete && !viewModel.hasErrors {
                    showingResults = true
                }
            }
        }) {
            ZStack {
                if viewModel.isAnalyzing {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        Text("ANALYZING...")
                            .font(.system(size: 14, weight: .bold))
                            .tracking(1.2)
                    }
                } else {
                    Text("ANALYZE TEAM")
                        .font(.system(size: 14, weight: .bold))
                        .tracking(1.2)
                }
            }
        }
        .primaryButtonStyle()
        .disabled(!viewModel.canAnalyze() || viewModel.isAnalyzing)
        .opacity(viewModel.canAnalyze() ? 1 : 0.5)
        .scaleEffect(viewModel.isAnalyzing ? 0.95 : 1)
        .animation(.spring(response: 0.3), value: viewModel.isAnalyzing)
        .padding(.vertical, DesignSystem.Spacing.md)
    }
}

struct ModernInputField: View {
    let index: Int
    @Binding var text: String
    let error: String?
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                TextField("", text: $text)
                    .placeholder(when: text.isEmpty) {
                        Text("Summoner#TAG")
                            .foregroundColor(DesignSystem.Colors.secondaryText.opacity(0.5))
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($isFocused)
                
                if index < 2 {
                    Text("REQUIRED")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.amber)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(DesignSystem.Colors.amber.opacity(0.2))
                        .cornerRadius(4)
                }
                
                if error != nil {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(DesignSystem.Colors.lossRed)
                        .font(.system(size: 14))
                }
            }
            .padding(DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.darkGray)
            .cornerRadius(DesignSystem.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(
                        error != nil ? DesignSystem.Colors.lossRed :
                        isFocused ? DesignSystem.Colors.primaryAccent :
                        Color.clear,
                        lineWidth: 2
                    )
            )
            
            if let error = error {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(DesignSystem.Colors.lossRed)
                    .padding(.horizontal, 4)
            }
        }
    }
}

struct GameCountChip: View {
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(count)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(isSelected ? .white : DesignSystem.Colors.secondaryText)
                
                Text("GAMES")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : DesignSystem.Colors.secondaryText.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                isSelected ?
                LinearGradient(
                    colors: [DesignSystem.Colors.primaryAccent, DesignSystem.Colors.primaryAccent.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) :
                LinearGradient(
                    colors: [DesignSystem.Colors.darkGray, DesignSystem.Colors.darkGray],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(DesignSystem.CornerRadius.medium)
            .scaleEffect(isSelected ? 1.05 : 1)
        }
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
