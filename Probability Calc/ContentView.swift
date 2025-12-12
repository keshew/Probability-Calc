import SwiftUI
import Charts

struct ContentView: View {
    var body: some View {
        TabView {
            DiceScreen()
                .tabItem {
                    Image(systemName: "dice")
                    Text("Dice")
                }
            
            CardsScreen()
                .tabItem {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Cards")
                }
            
            TournamentScreen()
                .tabItem {
                    Image(systemName: "trophy")
                    Text("Tournament")
                }
            
            SettingsScreen()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
}

struct DiceScreen: View {
    @State private var diceCount = 3
    @State private var diceType = 6
    @State private var targetSum = 10
    @State private var probability: Double = 0.0
    @State private var simulationResults: [Int] = []
    @State private var isAnimating = false
    @State private var showDiceRoll = false
    
    let diceTypes = [4, 6, 8, 10, 12, 20]
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.05), Color.blue.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var buttonGradient: some View {
        LinearGradient(
            colors: [.blue, .blue.opacity(0.7), Color.blue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    HStack {
                        Image(systemName: "dice.fill")
                            .font(.system(size: 35))
                            .foregroundStyle(.blue)
                            .symbolEffect(.pulse, options: .repeating)
                        VStack(alignment: .leading) {
                            Text("Dice Probability")
                                .font(.largeTitle.bold())
                                .foregroundStyle(.primary)
                            Text("Calculate your chances")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    parametersCard
                    
                    resultCard
                    
                    actionButtons
                    
                    if !simulationResults.isEmpty {
                        histogramCard
                    }
                }
                .padding()
            }
            .background(backgroundGradient)
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: diceCount) { _, newValue in
                let minSum = newValue * 1
                let maxSum = newValue * diceType
                targetSum = min(max(targetSum, minSum), maxSum)
            }

            .onChange(of: diceType) { _, newValue in
                let minSum = diceCount * 1
                let maxSum = diceCount * newValue
                targetSum = min(max(targetSum, minSum), maxSum)
            }

        }
    }
    
    private var parametersCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("🎲 Parameters")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Group {
                diceParameter("dice", value: $diceCount, label: "Dice Count", range: 1...10)
                diceParameter("cube", value: $diceType, label: "Dice Type", options: diceTypes)
                diceParameter("target", value: $targetSum, label: "Target Sum", range: 3...50)
            }
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                .shadow(color: .white.opacity(0.3), radius: 10, x: 0, y: -5)
        )
    }
    
    private var resultCard: some View {
        VStack(spacing: 15) {
            Text("🎯 Chance")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(.blue.opacity(0.3), lineWidth: 8)
                    )
                
                VStack {
                    Text("\(probability, specifier: "%.1f")%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                    
                    Text(probability > 50 ? "Excellent!" : probability > 20 ? "Good" : "Tough")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            
            ProgressView(value: probability / 100)
                .scaleEffect(x: 1.05, y: 1.1)
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                .shadow(color: .white.opacity(0.3), radius: 10, x: 0, y: -5)
        )
        .onChange(of: probability) { _, _ in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isAnimating = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isAnimating = false
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 20) {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    probability = calculateDiceProbability()
                }
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "function")
                        .font(.title2)
                    Text("Calculate")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(buttonGradient)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .blue.opacity(0.4), radius: 15, x: 0, y: 8)
            }
            
            Button {
                simulateRolls()
                showDiceRoll = true
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .font(.title2)
                    Text("100x Roll")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .orange.opacity(0.4), radius: 15, x: 0, y: 8)
            }
        }
    }
    
    private var histogramCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("📈 Simulation Results")
                    .font(.headline)
                Spacer()
                Text("\(simulationResults.count) rolls")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Chart {
                ForEach(simulatedSumsFrequencies(), id: \.sum) { data in
                    BarMark(
                        x: .value("Sum", data.sum),
                        y: .value("Frequency", data.frequency)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue.opacity(0.7), .purple.opacity(0.7)],
                            startPoint: .bottom,
                            endPoint: .topLeading
                        )
                    )
                    .annotation(position: .overlay, alignment: .center) {
                        Text("\(data.frequency)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                    }
                }
            }
            .frame(height: 220)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic)
            }
            .chartXAxis {
                AxisMarks(position: .leading, values: .automatic)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                .shadow(color: .white.opacity(0.3), radius: 10, x: 0, y: -5)
        )
    }
    
    @ViewBuilder
    private func diceParameter(
        _ icon: String,
        value: Binding<Int>,
        label: String,
        range: ClosedRange<Int>? = nil,
        options: [Int]? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                    .font(.title3)
                
                Text(label)
                    .font(.subheadline.weight(.medium))
            }

            HStack {
                if let options = options {
                    Picker("Type", selection: value) {
                        ForEach(options, id: \.self) { type in
                            Text("D\(type)").tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                } else if let range = range {
                    HStack(spacing: 4) {
                        Text("\(value.wrappedValue)")
                            .font(.subheadline.weight(.medium))
                            .frame(width: 40, alignment: .trailing)
                        
                        Stepper("", value: value, in: range)
                            .font(.subheadline)
                            .labelsHidden()
                    }
                }
            }
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 8)
    }
}

extension DiceScreen {
    func calculateDiceProbability() -> Double {
        let minSum = diceCount * 1
        let maxSum = diceCount * diceType

        guard targetSum >= minSum, targetSum <= maxSum else {
            return 0
        }

        var ways = Array(repeating: 0, count: maxSum + 1)
        ways[0] = 1

        for _ in 0..<diceCount {
            var newWays = Array(repeating: 0, count: maxSum + 1)
            for sum in 0...maxSum where ways[sum] > 0 {
                for face in 1...diceType {
                    let newSum = sum + face
                    if newSum <= maxSum {
                        newWays[newSum] += ways[sum]
                    }
                }
            }
            ways = newWays
        }

        let totalOutcomes = pow(Double(diceType), Double(diceCount))
        return Double(ways[targetSum]) / totalOutcomes * 100.0
    }

    
    func simulateRolls() {
        simulationResults = (0..<100).map { _ in
            (1...diceCount).map { _ in Int.random(in: 1...diceType) }.reduce(0, +)
        }
    }
    
    func simulatedSumsFrequencies() -> [(sum: Int, frequency: Int)] {
        let counts = Dictionary(grouping: simulationResults, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.key < $1.key }
        return counts.map { (sum: $0.key, frequency: $0.value) }
    }
}

struct CardsScreen: View {
    @State private var deckType = 0
    @State private var handSize = 5
    @State private var targetHand = "Pair"
    @State private var probability: Double = 0.0
    @State private var simulatedHand: [String] = []
    @State private var isAnimating = false
    
    let decks = ["Poker (52)", "Russian (36)", "Tarot (78)"]
    let hands = ["Pair", "Two Pair", "Flush", "Straight", "Full House"]
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color.red.opacity(0.1), Color.purple.opacity(0.05), Color.red.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var buttonGradient: some View {
        LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right.fill")
                            .font(.system(size: 35))
                            .foregroundStyle(.red)
                            .symbolEffect(.pulse, options: .repeating)
                        
                        VStack(alignment: .leading) {
                            Text("Cards Probability")
                                .font(.largeTitle.bold())
                            Text("Poker odds calculator")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    parametersCard
                    
                    resultCard
                    
                    actionButtons
                    
                    if !simulatedHand.isEmpty {
                        handCard
                    }
                }
                .padding()
            }
            .background(backgroundGradient)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var parametersCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("🃏 Setup")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Group {
                cardParameter("rectangle.stack", value: $deckType, label: "Deck", options: Array(0..<decks.count))
                cardParameter("person.2", value: $handSize, label: "Hand Size", range: 2...7)
            }
        }
        .padding(25)
        .glassCardStyle()
    }
    
    private var resultCard: some View {
        VStack(spacing: 15) {
            Text("🎰 Odds")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)
                    .overlay(Circle().stroke(.red.opacity(0.3), lineWidth: 8))
                
                VStack {
                    Text("\(probability, specifier: "%.2f")%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient(colors: [.red, .orange], startPoint: .top, endPoint: .bottom))
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                    
                    Text(oddsStatus)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            
            ProgressView(value: probability / 100)
                .frame(height: 12)
        }
        .padding(25)
        .glassCardStyle()
        .onChange(of: probability) { _, _ in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isAnimating = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isAnimating = false
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 20) {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    probability = calculateCardProbability()
                }
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "function")
                        .font(.title2)
                    Text("Calculate")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(buttonGradient)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .red.opacity(0.4), radius: 15, x: 0, y: 8)
            }
            
            Button {
                dealRandomHand()
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.title2)
                    Text("Deal Hand")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .purple.opacity(0.4), radius: 15, x: 0, y: 8)
            }
        }
    }
    
    private var handCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("🂱 Your Hand")
                    .font(.headline)
                Spacer()
                Text("\(simulatedHand.count) cards")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: max(4, handSize)), spacing: 12) {
                ForEach(Array(simulatedHand.enumerated()), id: \.offset) { index, card in
                    cardView(for: card, at: index)
                }
            }
        }
        .padding(20)
        .glassCardStyle()
    }
    
    @ViewBuilder
    private func cardParameter(
        _ icon: String,
        value: Binding<Int>,
        label: String,
        range: ClosedRange<Int>? = nil,
        options: [Int]? = nil,
        stringOptions: [String]? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.red)
                    .font(.title3)
                Text(label)
                    .font(.subheadline.weight(.medium))
            }
            
            HStack {
                if let options = options {
                    Picker("", selection: value) {
                        ForEach(options, id: \.self) { i in
                            Text(decks[i]).tag(i)
                        }
                    }
                    .pickerStyle(.segmented)
                } else if let stringOptions = stringOptions {
                    Picker("", selection: Binding(
                        get: { targetHand },
                        set: { targetHand = $0 }
                    )) {
                        ForEach(stringOptions, id: \.self) { hand in
                            Text(hand).tag(hand)
                        }
                    }
                    .pickerStyle(.menu)
                } else if let range = range {
                    HStack(spacing: 4) {
                        Text("\(value.wrappedValue)")
                            .font(.subheadline.weight(.medium))
                            .frame(width: 40)
                        Stepper("", value: value, in: range)
                            .labelsHidden()
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
    
    @ViewBuilder
    private func cardView(for card: String, at index: Int) -> some View {
        Text(card)
            .font(.title2.weight(.bold))
            .frame(width: 55, height: 80)
            .background(
                LinearGradient(
                    colors: [.white.opacity(0.9), .white.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.2), lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            .rotationEffect(.degrees(Double(index * 2 - simulatedHand.count)))
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: simulatedHand)
    }
    
    private var oddsStatus: String {
        switch probability {
        case 30...: return "Great odds!"
        case 10..<30: return "Decent"
        case 1..<10: return "Rare"
        default: return "Long shot"
        }
    }
}

extension View {
    func glassCardStyle() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .shadow(color: .white.opacity(0.3), radius: 10, x: 0, y: -5)
            )
    }
}

extension CardsScreen {
    func calculateCardProbability() -> Double {
        let deckSize = [52, 36, 78][deckType]
        switch targetHand {
        case "Pair": return 42.256 / 100
        case "Flush": return 0.197 / 100
        case "Straight": return 0.392 / 100
        default: return 1.0 / Double(deckSize)
        }
    }
    
    func dealRandomHand() {
        let suits = ["♠", "♥", "♦", "♣"]
        let ranks = (2...10).map { "\($0)" } + ["J", "Q", "K", "A"]
        simulatedHand = (0..<handSize).map { _ in
            "\(ranks.randomElement() ?? "A")\(suits.randomElement() ?? "♠")"
        }
        probability = calculateCardProbability()
    }
}

struct TournamentScreen: View {
    @State private var challenges: [Challenge] = []
    @State private var currentChallenge: Challenge?
    
    struct Challenge: Identifiable, Codable {
        var id = UUID()
        var name: String
        var probability: Double
        var attempts: Int
        var successes: Int
    }
    
    private var backgroundGradient: some View {
        LinearGradient(colors: [Color.yellow.opacity(0.1), Color.orange.opacity(0.05), Color.yellow.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    headerView
                    
                    if let challenge = currentChallenge {
                        currentChallengeCard(challenge)
                    } else {
                        startTournamentCard
                    }
                    
                    leaderboardCard
                }
                .padding()
            }
            .background(backgroundGradient)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { loadChallenges() }
        }
    }
    
    private var headerView: some View {
        HStack {
            Image(systemName: "trophy.fill")
                .font(.system(size: 40))
                .foregroundStyle(.yellow)
                .symbolEffect(.pulse, options: .repeating)
            VStack(alignment: .leading) {
                Text("Tournament")
                    .font(.largeTitle.bold())
                Text("Beat the odds!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private func currentChallengeCard(_ challenge: Challenge) -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Text(challenge.name)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                HStack {
                    Text("Chance: \(challenge.probability, specifier: "%.1f")%")
                        .font(.title3.bold())
                        .foregroundStyle(.yellow)
                    Spacer()
                }
                ProgressView(value: Double(challenge.successes) / Double(challenge.attempts + 1))
                    .frame(height: 12)
                Text("Success: \(Double(challenge.successes)/Double(challenge.attempts + 1)*100, specifier: "%.1f")%")
                    .font(.subheadline.weight(.semibold))
            }
            .padding(24)
            .background(LinearGradient(colors: [.orange.opacity(0.2), .yellow.opacity(0.1)], startPoint: .top, endPoint: .bottom))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2))
            
            HStack(spacing: 16) {
                Button("Attempt 100x") { attemptChallenge(challenge) }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .blue.opacity(0.4), radius: 15)
                
                Button("New") { generateNewChallenge() }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(LinearGradient(colors: [.gray, .gray.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .gray.opacity(0.3), radius: 10)
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color(.systemBackground)).shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 8))
    }
    
    private var startTournamentCard: some View {
        VStack(spacing: 20) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 80))
                .foregroundStyle(.yellow.opacity(0.3))
                .symbolEffect(.pulse)
            Text("Welcome to Tournament!")
                .font(.title2.bold())
            Text("Test your luck against the odds")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Start Tournament!") { generateNewChallenge() }
                .font(.title2.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .yellow.opacity(0.4), radius: 20)
        }
        .padding(40)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color(.systemBackground)).shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 8))
    }
    
    private var leaderboardCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("🥇 Leaderboard")
                    .font(.headline)
                Spacer()
                Text("\(challenges.count) challenges")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if challenges.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 50))
                        .foregroundStyle(.secondary.opacity(0.5))
                    Text("No challenges yet")
                        .foregroundStyle(.secondary)
                }
            } else {
                let sortedChallenges = challenges.sorted { $0.successes > $1.successes }
                ForEach(Array(sortedChallenges.enumerated()), id: \.offset) { index, challenge in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.title3.bold())
                            .frame(width: 32)
                            .foregroundStyle(index == 0 ? .yellow : .secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(challenge.name)
                                .font(.headline)
                                .lineLimit(1)
                            Text("\(challenge.successes)/\(challenge.attempts)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(String(format: "%.1f%%", challenge.probability))
                            .font(.subheadline.bold())
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color(.systemBackground)).shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 8))
    }
    
    func generateNewChallenge() {
        let templates = ["3D6 = 18", "4D8 ≥ 20", "2D20 max(15)", "Poker Flush", "Royal Straight"]
        currentChallenge = Challenge(name: templates.randomElement() ?? "Challenge", probability: Double.random(in: 0.1...25.0), attempts: 0, successes: 0)
    }
    
    func attemptChallenge(_ challenge: Challenge) {
        let successes = Int.random(in: 0...10)
        if var current = currentChallenge {
            current.attempts += 100
            current.successes += successes
            currentChallenge = current
            if !challenges.contains(where: { $0.id == current.id }) {
                challenges.append(current)
            }
        }
        saveChallenges()
    }
    
    func saveChallenges() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(challenges) {
            UserDefaults.standard.set(data, forKey: "challengesData")
        }
    }
    
    func loadChallenges() {
        if let data = UserDefaults.standard.data(forKey: "challengesData"),
           let decoded = try? JSONDecoder().decode([Challenge].self, from: data) {
            challenges = decoded
        }
    }
}

struct SettingsScreen: View {
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("animationsEnabled") private var animationsEnabled = true
    @AppStorage("challengesData") private var challengesData: Data = Data()
    
    @State private var showingExportSheet = false
    @State private var showingClearAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Toggle("Dark Mode", isOn: $darkMode)
                        .onChange(of: darkMode) { _, newValue in
                            if newValue {
                                UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .dark
                            } else {
                                UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .light
                            }
                        }
                    
                    Toggle("Animations", isOn: $animationsEnabled)
                }
                
                Section("Data") {
                    Button("Export History (CSV)") {
                        showingExportSheet = true
                    }
                    
                    Button("Clear All Data") {
                        showingClearAlert = true
                    }
                    .foregroundStyle(.red)
                }
                
                Section("About") {
                    HStack {
                        Image(systemName: "dice.fill")
                            .foregroundStyle(.blue)
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text("Probability Calc")
                                .font(.headline)
                            Text("v1.0")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    
                    Text("Probability calculator for dice, cards & tournaments")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Text("Total Challenges:")
                        Spacer()
                        Text("\(loadChallenges().count)")
                            .font(.headline)
                            .monospacedDigit()
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingExportSheet) {
                ExportCSVSheet(csvData: generateCSVData())
            }
            .alert("Clear All Data?", isPresented: $showingClearAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("This will delete all tournament history and settings. Cannot be undone.")
            }
        }
        .preferredColorScheme(darkMode ? .dark : .light)
    }
    
    private func generateCSVData() -> String {
        let challenges = loadChallenges()
        var csv = "Challenge,Probability,Attempts,Successes,Success Rate\n"
        
        for challenge in challenges {
            let successRate = Double(challenge.successes) / Double(challenge.attempts) * 100
            csv += "\"\(challenge.name)\",\(challenge.probability),\(challenge.attempts),\(challenge.successes),\(String(format: "%.2f", successRate))%\n"
        }
        
        return csv
    }
    
    private func clearAllData() {
        challengesData = Data()
                darkMode = false
        animationsEnabled = true
        
        UserDefaults.standard.removeObject(forKey: "challengesData")
        UserDefaults.standard.removeObject(forKey: "darkMode")
        UserDefaults.standard.removeObject(forKey: "animationsEnabled")
        
    }
    
    private func loadChallenges() -> [TournamentScreen.Challenge] {
        guard let data = try? JSONDecoder().decode([TournamentScreen.Challenge].self, from: challengesData) else {
            return []
        }
        return data
    }
    
    private func saveChallenges(_ challenges: [TournamentScreen.Challenge]) {
        if let data = try? JSONEncoder().encode(challenges) {
            challengesData = data
        }
    }
}

struct ExportCSVSheet: View {
    let csvData: String
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Tournament History")
                    .font(.title.bold())
                
                ScrollView {
                    Text(csvData)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button("Share CSV") {
                    showingShareSheet = true
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
            .padding()
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [csvData])
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
