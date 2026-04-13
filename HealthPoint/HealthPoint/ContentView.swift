//
//  ContentView.swift
//  HealthPoint
//
//  Created by Máximo Magallanes Urtuzuástegui on 10/04/26.
//

import SwiftUI
import SwiftData
import FoundationModels

struct ContentView: View {
    //Used to call swiftData model actions
    @Environment(\.modelContext) private var modelContext
    
    //References global environmentObject of current user
    @EnvironmentObject var currentUser: UserSettings
    
    @State private var prompt = ""
    @State private var response = ""
    @State private var isLoading = false
    @State private var selectedPersonality: ChatPersonality = .friendly
    @State private var usedContext: [String] = []

    private let orchestrator: ChatOrchestrator = {
        let retriever = KnowledgeRetriever(sources: [
            MockFAQSource(),
            MockAnalyticsSource()
        ])
        return ChatOrchestrator(retriever: retriever)
    }()
    
    var body: some View {
        
        TabView {
            MedicineExplorer()
                .tabItem {
                    Image(systemName: "plus")
                    Text("Data")
                }
            
            VStack(spacing: 16) {
                Text("Local AI Assistant")
                    .font(.title)
                    .bold()

                // Personality picker
                Picker("Personality", selection: $selectedPersonality) {
                    ForEach(ChatPersonality.allCases) { persona in
                        Text(persona.displayName).tag(persona)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                TextField("Enter your prompt...", text: $prompt, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .lineLimit(3, reservesSpace: true)

                Button(action: generate) {
                    if isLoading {
                        ProgressView().progressViewStyle(.circular)
                    } else {
                        Text("Generate Response")
                    }
                }
                .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        if !response.isEmpty {
                            Text(response)
                                .font(.body)
                        }

                        if !usedContext.isEmpty {
                            Divider()
                            Text("Used Context")
                                .font(.headline)
                            ForEach(Array(usedContext.enumerated()), id: \.offset) { idx, snippet in
                                Text("\(idx + 1). \(snippet)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .tabItem {
                    Image(systemName: "pencil")
                    Text("Chat")
                }
                .frame(maxHeight: 320)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .padding()
        }
    }
    private func generate() {
        isLoading = true
        response = ""
        usedContext = []
        let query = prompt.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            let answer = await orchestrator.answer(userQuery: query, personality: selectedPersonality)
            await MainActor.run {
                self.response = answer.content
                self.usedContext = answer.usedContext
                self.isLoading = false
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}

