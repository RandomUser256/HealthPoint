//
//  chatScreen.swift
//  HealthPoint
//
//  Created by Máximo on 4/14/26.
//
import SwiftUI
import SwiftData
import FoundationModels
import TimerKit
import AVFoundation
import TranscriptionKit

struct chatScreen: View {
    //Used to call swiftData model actions
    @Environment(\.modelContext) private var modelContext
    
    //References global environmentObject of current user
    @EnvironmentObject var currentUser: UserSettings
    
    //@State private var currentScreen: Screen = .menu
    @State private var hasLoadedConversation = false

    @State private var prompt = ""
    @State private var isLoading = false
    @State private var selectedPersonality: ChatPersonality = .friendly
    @State private var conversation: [ChatMessage] = [] // Oldest-first (top)
    @State private var isRecording = false
    
    @State var speechRecognizer = SpeechRecognizer()
    
    private let conversationStorageKey = "chat.conversation.v1"
    
    // Simple chat message model for the transcript
    private struct ChatMessage: Identifiable, Equatable, Codable {
        enum Role: String, Codable { case user, assistant }
        let id: UUID
        let role: Role
        let text: String
        let context: [String]?

        init(id: UUID = UUID(), role: Role, text: String, context: [String]?) {
            self.id = id
            self.role = role
            self.text = text
            self.context = context
        }
    }
    
    private let orchestrator: ChatOrchestrator = {
        let retriever = KnowledgeRetriever(sources: [
            MockFAQSource(),
            MockAnalyticsSource()
        ])
        return ChatOrchestrator(retriever: retriever)
    }()
    
    // MARK: - Components
    private func bubble(text: String, role: ChatMessage.Role) -> some View {
       let isUser = (role == .user)
       return Text(text)
           .padding(10)
           .background(isUser ? Color.accentColor.opacity(0.2) : Color(.secondarySystemBackground))
           .foregroundStyle(.primary)
           .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
           .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }
    
    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        guard let lastID = conversation.last?.id else { return }
        withAnimation {
            proxy.scrollTo(lastID, anchor: .bottom)
        }
    }
    
    // MARK: - Actions

    private func generate() {
        let query = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        isLoading = true
        // Append user message at the bottom of the conversation
        conversation.append(ChatMessage(role: .user, text: query, context: nil))
        prompt = ""

        Task {
            let answer = await orchestrator.answer(userQuery: query, personality: selectedPersonality)
            let assistant = ChatMessage(role: .assistant, text: answer.content, context: answer.usedContext)
            await MainActor.run {
                self.conversation.append(assistant)
                self.isLoading = false
            }
        }
    }
    
    private func toggleTranscript() {
        if isRecording {
            // Stop recording and insert the transcript into the prompt
            speechRecognizer.stopTranscribing()
            isRecording = false
            let text = speechRecognizer.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                if prompt.isEmpty {
                    prompt = text
                } else {
                    // Append with a separating space
                    prompt += (prompt.hasSuffix(" ") ? "" : " ") + text
                }
            }
            // Clear for the next dictation session
            speechRecognizer.resetTranscript()
        } else {
            // Start a fresh dictation session in Spanish (Mexico) if supported
            speechRecognizer.resetTranscript()
            _ = Locale(identifier: "es-MX")
            // If TranscriptionKit supports a locale parameter, this will use it; otherwise it will fall back to default behavior.
            speechRecognizer.startTranscribing()
            isRecording = true
        }
    }
    
    // MARK: - Persistence
    private func saveConversation() {
        do {
            let data = try JSONEncoder().encode(conversation)
            UserDefaults.standard.set(data, forKey: conversationStorageKey)
        } catch {
            // Handle encoding error if needed
        }
    }

    private func loadConversation() {
        guard let data = UserDefaults.standard.data(forKey: conversationStorageKey) else { return }
        do {
            let loaded = try JSONDecoder().decode([ChatMessage].self, from: data)
            conversation = loaded
        } catch {
            // Handle decoding error if needed
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            @State var speechRecognizer = SpeechRecognizer()
            
            // Personality picker
            Picker("Personality", selection: $selectedPersonality) {
                ForEach(ChatPersonality.allCases) { persona in
                    Text(persona.displayName).tag(persona)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // Conversation view (oldest messages at the top, newest at the bottom)
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(conversation) { message in
                            HStack {
                                if message.role == .assistant {
                                    bubble(text: message.text, role: ChatMessage.Role.assistant)
                                    Spacer(minLength: 30)
                                } else {
                                    Spacer(minLength: 30)
                                    bubble(text: message.text, role: ChatMessage.Role.user)
                                }
                            }
                            .padding(.horizontal)
                            .id(message.id)
                        }
                    }
                    .padding(.top, 4)
                }
                .onAppear {
                    scrollToBottom(proxy)
                }
                .onChange(of: conversation.count) { oldVal, newVal in
                    scrollToBottom(proxy)
                }
            }

            // Input area
            HStack(alignment: .bottom, spacing: 8) {
                
                Button(action: toggleTranscript) {
                    Image(systemName: isRecording ? "stop.circle.fill" : "mic.fill")
                        .font(.title3)
                        .foregroundStyle(isRecording ? .red : .primary)
                        .accessibilityLabel(isRecording ? "Detener grabación" : "Grabar voz")
                        .accessibilityHint("Dicta tu mensaje en español (México)")
                }
                .buttonStyle(.bordered)

                TextField("Type a message...", text: $prompt, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3, reservesSpace: true)

                Button(action: generate) {
                    if isLoading {
                        ProgressView().progressViewStyle(.circular)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.title3)
                    }
                }
                .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}
