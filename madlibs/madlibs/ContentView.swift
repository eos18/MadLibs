//
//  ContentView.swift
//  madlibs
//
//  Created by English, Kate on 4/7/25.
//

import SwiftUI
import Foundation

struct ContentView: View {
    @State private var adjectivesInput = ""
    @State private var nounsInput = ""
    @State private var verbsInput = ""
    @State private var story = ""
    @State private var favorites: [String] = []
    @State private var selectedTab = 1

    @State private var customTemplate = ""
    @State private var customStory = ""

    @State private var showCustomFavConfirmation = false

    var body: some View {
        TabView(selection: $selectedTab) {

            // Favorites Tab
            NavigationStack {
                FavoritesView(favorites: $favorites)
            }
            .tabItem {
                Label("Favorites", systemImage: "heart.fill")
            }
            .tag(0)

            // Home Tab
            NavigationStack {
                VStack(spacing: 20) {
                    Text("Mad Libs Generator")
                        .font(.largeTitle)
                        .bold()
                        .padding(.top)

                    Group {
                        TextField("Enter adjectives (comma-separated)", text: $adjectivesInput)
                        TextField("Enter nouns (comma-separated)", text: $nounsInput)
                        TextField("Enter verbs (comma-separated)", text: $verbsInput)
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                    HStack(spacing: 15) {
                        Button("Generate Random Story") {
                            let adjectives = adjectivesInput.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }.filter { !$0.isEmpty }
                            let nouns = nounsInput.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }.filter { !$0.isEmpty }
                            let verbs = verbsInput.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }.filter { !$0.isEmpty }

                            guard !adjectives.isEmpty, !nouns.isEmpty, !verbs.isEmpty else {
                                story = "Please enter at least one adjective, noun, and verb."
                                return
                            }

                            story = getRandomStory(adjectives: adjectives, nouns: nouns, verbs: verbs)
                            selectedTab = 2
                        }
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)

                        Button("Clear All") {
                            adjectivesInput = ""
                            nounsInput = ""
                            verbsInput = ""
                        }
                        .padding()
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(10)
                    }

                    Spacer()
                }
                .padding()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(1)

            // Story View Tab
            NavigationStack {
                StoryView(story: story, favorites: $favorites)
            }
            .tabItem {
                Label("Recent Story", systemImage: "pencil.circle.fill")
            }
            .tag(2)

            // Custom Builder Tab
            NavigationStack {
                ZStack {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Custom Story Builder")
                            .font(.title)
                            .bold()

                        Text("On the Home page, enter your words into the mad libs generator. Then, write your story in the builder! Use {adjective}, {noun}, and {verb} as placeholders in your custom template.")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        TextEditor(text: $customTemplate)
                            .frame(height: 200)
                            .padding()
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.5)))

                        // Center-aligned buttons section
                        HStack {
                            Button("Generate Custom Story") {
                                let adjectives = adjectivesInput.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }.filter { !$0.isEmpty }
                                let nouns = nounsInput.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }.filter { !$0.isEmpty }
                                let verbs = verbsInput.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }.filter { !$0.isEmpty }

                                customStory = generateFromTemplate(template: customTemplate, adjectives: adjectives, nouns: nouns, verbs: verbs)
                            }
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .frame(maxWidth: .infinity)

                            Button("Add to Favorites") {
                                if !favorites.contains(customStory) {
                                    favorites.append(customStory)
                                    withAnimation {
                                        showCustomFavConfirmation = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation {
                                            showCustomFavConfirmation = false
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity)

                        if !customStory.isEmpty {
                            Text("Your Custom Story:")
                                .font(.headline)
                            ScrollView {
                                Text(customStory)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                            }
                        }

                        Spacer()
                    }
                    .padding()

                    // Overlay popup
                    if showCustomFavConfirmation {
                        VStack {
                            Text("Added to Favorites!")
                                .padding()
                                .background(Color.black.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .transition(.opacity)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.clear)
                        .zIndex(1)
                    }
                }
            }
            .tabItem {
                Label("Builder", systemImage: "wand.and.stars")
            }
            .tag(3)
        }
        .accentColor(.orange)
    }

    func getRandomStory(adjectives: [String], nouns: [String], verbs: [String]) -> String {
        let stories: [([String], [String], [String]) -> String] = [
            storyAdventure,
            storyFairyTale,
            storySciFi,
            storyPoem,
            storyMystery,
            storyRobot,
            storyMagicSchool,
            storyVacation,
            storyZombies
        ]
        let index = Int.random(in: 0..<stories.count)
        return stories[index](adjectives, nouns, verbs)
    }

    func capitalizeSentences(in text: String) -> String {
        let pattern = #"(?<=[\.!\?]\s|^)[a-z]"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        var newText = text
        if let matches = regex?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) {
            for match in matches.reversed() {
                if let range = Range(match.range, in: newText) {
                    let capital = newText[range].uppercased()
                    newText.replaceSubrange(range, with: capital)
                }
            }
        }
        return newText
    }

    func generateFromTemplate(template: String, adjectives: [String], nouns: [String], verbs: [String]) -> String {
        var result = template
        var adjIndex = 0, nounIndex = 0, verbIndex = 0

        while let range = result.range(of: "{adjective}") {
            if adjIndex < adjectives.count {
                result.replaceSubrange(range, with: adjectives[adjIndex])
                adjIndex += 1
            } else { break }
        }
        while let range = result.range(of: "{noun}") {
            if nounIndex < nouns.count {
                result.replaceSubrange(range, with: nouns[nounIndex])
                nounIndex += 1
            } else { break }
        }
        while let range = result.range(of: "{verb}") {
            if verbIndex < verbs.count {
                result.replaceSubrange(range, with: verbs[verbIndex])
                verbIndex += 1
            } else { break }
        }
        return capitalizeSentences(in: result)
    }

    func repeatList(_ list: [String], toCount count: Int) -> [String] {
        if list.count >= count { return Array(list[0..<count]) }
        return Array(repeating: list, count: (count / list.count) + 1).flatMap { $0 }.prefix(count).map { $0 }
    }

    // MARK: - Adventure Story

    func storyAdventure(adjectives: [String], nouns: [String], verbs: [String]) -> String {
        let base = "It all began on a windy morning, deep in the heart of an ancient jungle."
        let end = "By sunset, they reached the top of the tallest peak, looked out across the world, and felt truly alive."

        var lines = [base]

        if adjectives.count > 0, nouns.count > 0, verbs.count > 0 {
            lines.append("There, a \(adjectives[0]) \(nouns[0]) began their journey to \(verbs[0]) through wild vines and roaring rivers.")
        }
        if adjectives.count > 1, nouns.count > 1, verbs.count > 1 {
            lines.append("Along the way, they encountered a \(adjectives[1]) \(nouns[1]) that tried to stop them, forcing them to \(verbs[1]) to survive.")
        }
        if adjectives.count > 2, nouns.count > 2, verbs.count > 2 {
            lines.append("Later, a mysterious cave revealed a \(adjectives[2]) \(nouns[2]), which they had to \(verbs[2]) to uncover its secrets.")
        }
        if adjectives.count > 3, nouns.count > 3, verbs.count > 3 {
            lines.append("At dusk, a tribe of \(adjectives[3]) \(nouns[3])s welcomed them, showing them how to \(verbs[3]) in harmony with the wild.")
        }

        lines.append(end)
        return capitalizeSentences(in: lines.joined(separator: " "))
    }

    // MARK: - Fairy Tale Story

    func storyFairyTale(adjectives: [String], nouns: [String], verbs: [String]) -> String {
        var lines = [String]()

        // Intro sentence
        let introAdj = adjectives.first ?? "mysterious"
        let introNoun = nouns.first ?? "prince"
        lines.append("Once upon a time, in a \(introAdj) kingdom, there lived a lonely \(introNoun).")

        // Gradual narrative build-up
        if adjectives.count > 0, nouns.count > 1 {
            lines.append("One morning, the \(nouns[0]) discovered a \(adjectives[0]) \(nouns[1]) hidden beneath the castle.")
        }

        if adjectives.count > 1, nouns.count > 2, verbs.count > 0 {
            lines.append("With help from a \(adjectives[1]) \(nouns[2]), they learned to \(verbs[0]) like never before.")
        }

        if adjectives.count > 2, nouns.count > 3, verbs.count > 1 {
            lines.append("Their journey took them past a \(adjectives[2]) \(nouns[3]), where they had to \(verbs[1]) to escape.")
        }

        if adjectives.count > 3, nouns.count > 4, verbs.count > 2 {
            lines.append("In the heart of the forest, a \(adjectives[3]) \(nouns[4]) taught them to \(verbs[2]) with courage.")
        }

        if adjectives.count > 4, nouns.count > 5, verbs.count > 3 {
            lines.append("At last, they faced a \(adjectives[4]) \(nouns[5]) and used their power to \(verbs[3]) and save the realm.")
        }

        // Closing sentence
        lines.append("And from that day forward, the kingdom knew peace and joy beyond measure.")

        return capitalizeSentences(in: lines.joined(separator: " "))
    }

    // MARK: - Sci-Fi Story

    func storySciFi(adjectives: [String], nouns: [String], verbs: [String]) -> String {
        let base = "In the year 3042, a \(adjectives.first ?? "brilliant") scientist discovered a way to \(verbs.first ?? "travel") through time using a \(nouns.first ?? "machine")."
        let end = "The universe was never the same again."

        var lines = [base]

        if adjectives.count > 1, nouns.count > 1, verbs.count > 1 {
            lines.append("The \(adjectives[1]) \(nouns[1]) malfunctioned, causing a rift that made everything \(verbs[1]) uncontrollably.")
        }
        if adjectives.count > 2, nouns.count > 2, verbs.count > 2 {
            lines.append("A crew of \(adjectives[2]) explorers boarded a \(nouns[2]) to \(verbs[2]) into the unknown.")
        }
        if adjectives.count > 3, nouns.count > 3, verbs.count > 3 {
            lines.append("They encountered a \(adjectives[3]) civilization on planet \(nouns[3]), and had to \(verbs[3]) to earn their trust.")
        }
        if adjectives.count > 4, nouns.count > 4, verbs.count > 4 {
            lines.append("With help from a \(adjectives[4]) AI embedded in the \(nouns[4]), they finally managed to \(verbs[4]) time itself.")
        }

        lines.append(end)
        return capitalizeSentences(in: lines.joined(separator: " "))
    }

    // MARK: - Poem Story

    func storyPoem(adjectives: [String], nouns: [String], verbs: [String]) -> String {
        var lines: [String] = []

        if adjectives.count > 0, nouns.count > 0, verbs.count > 0 {
            lines.append("A \(adjectives[0]) \(nouns[0]) likes to \(verbs[0]),")
        }
        if adjectives.count > 1, nouns.count > 1, verbs.count > 1 {
            lines.append("On a \(adjectives[1]) hill, with a \(nouns[1]) to \(verbs[1]).")
        }
        if adjectives.count > 2, nouns.count > 2, verbs.count > 2 {
            lines.append("Every \(adjectives[2]) day, they \(verbs[2]) so free,")
            lines.append("By the \(nouns[2]), in harmony.")
        }
        if adjectives.count > 3, nouns.count > 3, verbs.count > 3 {
            lines.append("A \(adjectives[3]) breeze, a \(nouns[3]) bright,")
            lines.append("They \(verbs[3]) onward into the night.")
        }

        if lines.isEmpty {
            lines.append("A lonely breeze whispers past, with stories never told.")
        }

        return capitalizeSentences(in: lines.joined(separator: " "))
    }
    
    // MARK: - Mystery Story

    func storyMystery(adjectives: [String], nouns: [String], verbs: [String]) -> String {
        var lines = ["It was a \(adjectives.first ?? "dark") night when the case began."]

        if adjectives.count > 0, nouns.count > 0, verbs.count > 0 {
            lines.append("The detective found a \(adjectives[0]) \(nouns[0]) that hinted they must \(verbs[0]) immediately.")
        }
        if adjectives.count > 1, nouns.count > 1, verbs.count > 1 {
            lines.append("A clue at the scene—a \(adjectives[1]) \(nouns[1])—forced them to \(verbs[1]) deeper into the case.")
        }
        if adjectives.count > 2, nouns.count > 2, verbs.count > 2 {
            lines.append("In a dusty archive, a \(adjectives[2]) \(nouns[2]) revealed the truth, leading to a daring \(verbs[2]).")
        }
        if adjectives.count > 3, nouns.count > 3, verbs.count > 3 {
            lines.append("At last, a confrontation with a \(adjectives[3]) \(nouns[3]) required them to \(verbs[3]) one final time.")
        }

        lines.append("By sunrise, the mystery was solved, but the city would never be the same.")
        return capitalizeSentences(in: lines.joined(separator: " "))
    }

    // MARK: - Robot Story

    func storyRobot(adjectives: [String], nouns: [String], verbs: [String]) -> String {
        var lines = ["In a future overrun by machines, humanity had one last hope."]

        if adjectives.count > 0, nouns.count > 0, verbs.count > 0 {
            lines.append("A \(adjectives[0]) \(nouns[0]) was designed to \(verbs[0]) with precision and purpose.")
        }
        if adjectives.count > 1, nouns.count > 1, verbs.count > 1 {
            lines.append("Its mission led it to a \(adjectives[1]) \(nouns[1]), where it had to \(verbs[1]) under pressure.")
        }
        if adjectives.count > 2, nouns.count > 2, verbs.count > 2 {
            lines.append("With the help of a \(adjectives[2]) companion \(nouns[2]), it managed to \(verbs[2]) the central core.")
        }
        if adjectives.count > 3, nouns.count > 3, verbs.count > 3 {
            lines.append("The final battle against a \(adjectives[3]) \(nouns[3]) forced it to \(verbs[3]) for survival.")
        }

        lines.append("With sparks flying and circuits buzzing, the fate of Earth changed forever.")
        return capitalizeSentences(in: lines.joined(separator: " "))
    }

    // MARK: - Magic School Story

    func storyMagicSchool(adjectives: [String], nouns: [String], verbs: [String]) -> String {
        var lines = ["Welcome to the \(adjectives.first ?? "Wondrous") Academy of Magical Arts!"]

        if adjectives.count > 0, nouns.count > 0, verbs.count > 0 {
            lines.append("First years receive a \(adjectives[0]) \(nouns[0]) and learn to \(verbs[0]) during orientation.")
        }
        if adjectives.count > 1, nouns.count > 1, verbs.count > 1 {
            lines.append("In Potions class, a \(adjectives[1]) \(nouns[1]) nearly exploded when a student tried to \(verbs[1]).")
        }
        if adjectives.count > 2, nouns.count > 2, verbs.count > 2 {
            lines.append("During exams, students must tame a \(adjectives[2]) \(nouns[2]) and \(verbs[2]) flawlessly.")
        }
        if adjectives.count > 3, nouns.count > 3, verbs.count > 3 {
            lines.append("The final test involves summoning a \(adjectives[3]) \(nouns[3]) and commanding it to \(verbs[3]).")
        }

        lines.append("Graduation ends with a glowing ceremony and a magical fireworks show.")
        return capitalizeSentences(in: lines.joined(separator: " "))
    }

    // MARK: - Vacation Story

    func storyVacation(adjectives: [String], nouns: [String], verbs: [String]) -> String {
        var lines = ["The vacation was supposed to be relaxing..."]

        if adjectives.count > 0, nouns.count > 0, verbs.count > 0 {
            lines.append("But then a \(adjectives[0]) \(nouns[0]) appeared, and we had to \(verbs[0]) for our lives!")
        }
        if adjectives.count > 1, nouns.count > 1, verbs.count > 1 {
            lines.append("Next, a \(adjectives[1]) \(nouns[1]) blocked the road, so we had no choice but to \(verbs[1]) around it.")
        }
        if adjectives.count > 2, nouns.count > 2, verbs.count > 2 {
            lines.append("A \(adjectives[2]) \(nouns[2]) in the hotel made us \(verbs[2]) all night.")
        }
        if adjectives.count > 3, nouns.count > 3, verbs.count > 3 {
            lines.append("Finally, a \(adjectives[3]) \(nouns[3]) tried to overcharge us until we had to \(verbs[3]).")
        }

        lines.append("We made it home safely, but we’re never booking with that travel site again.")
        return capitalizeSentences(in: lines.joined(separator: " "))
    }

    // MARK: - Zombies Story

    func storyZombies(adjectives: [String], nouns: [String], verbs: [String]) -> String {
        var lines = ["The outbreak started small, just one \(adjectives.first ?? "rotting") \(nouns.first ?? "corpse") in a dark alley."]

        if adjectives.count > 0, nouns.count > 0, verbs.count > 0 {
            lines.append("We had to \(verbs[0]) quickly before the \(adjectives[0]) \(nouns[0]) saw us.")
        }
        if adjectives.count > 1, nouns.count > 1, verbs.count > 1 {
            lines.append("A group of \(adjectives[1]) \(nouns[1])s blocked the bridge, forcing us to \(verbs[1]) underground.")
        }
        if adjectives.count > 2, nouns.count > 2, verbs.count > 2 {
            lines.append("While scavenging, we found a \(adjectives[2]) \(nouns[2]) that could help us \(verbs[2]).")
        }
        if adjectives.count > 3, nouns.count > 3, verbs.count > 3 {
            lines.append("Our final stand came against a horde led by a \(adjectives[3]) \(nouns[3]), and we had to \(verbs[3]) with everything we had.")
        }

        lines.append("Hope is fading, but we haven’t given up yet.")
        return capitalizeSentences(in: lines.joined(separator: " "))
    }
}

// FavoritesView Inline
struct FavoritesView: View {
    @Binding var favorites: [String]

    var body: some View {
        VStack {
            Text("Favorite Stories")
                .font(.title)
                .bold()
                .padding()

            if favorites.isEmpty {
                Text("No favorites yet!")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ScrollView {
                    ForEach(favorites, id: \.self) { story in
                        HStack {
                            Text(story)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(radius: 2)
                            Spacer()
                            Button(action: {
                                if let index = favorites.firstIndex(of: story) {
                                    favorites.remove(at: index)
                                }
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .padding(.trailing)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                }
            }
        }
        .padding()
    }
}

// StoryView Inline
struct StoryView: View {
    let story: String
    @Binding var favorites: [String]
    @State private var showConfirmation = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Your Mad Lib Story")
                .font(.title)
                .bold()
                .padding(.top)

            ScrollView {
                Text(story)
                    .padding()
                    .multilineTextAlignment(.leading)
            }

            Button("Add to Favorites") {
                if !favorites.contains(story) {
                    favorites.append(story)
                    withAnimation { showConfirmation = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { showConfirmation = false }
                    }
                }
            }
            .padding()
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()

        if showConfirmation {
            VStack {
                Text("Added to Favorites!")
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .transition(.opacity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
            .zIndex(1)
        }
    }
}

#Preview {
    ContentView()
}
