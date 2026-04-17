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
    // Used to call swiftData model actions
    @Environment(\.modelContext) private var modelContext

    // References global environmentObject of current user
    @EnvironmentObject var currentUser: UserSettings

    @State private var prompt = ""
    @State private var isLoading = false
    @State private var selectedPersonality: ChatPersonality = .amaro
    @State private var conversation: [ChatMessage] = [] // Oldest-first (top)
    @State private var isRecording = false
    @State private var isDetailed = false
    @State private var textSize: Double = 17

    // Lazily built on first .onAppear so modelContext is available.
    @State private var orchestrator: ChatOrchestrator?

    @State var speechRecognizer = SpeechRecognizer()

    // Storage key per current user
    private func conversationStorageKey() -> String {
        "chat.conversation.\(currentUser.user.getName()).v1"
    }

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

    // MARK: - Orchestrator factory
    /// Builds the ChatOrchestrator once we have access to the SwiftData ModelContext.
    private func makeOrchestrator(context: ModelContext) -> ChatOrchestrator {
        let retriever = KnowledgeRetriever(sources: [
            MedicineDatabaseSource(context: context),   // ← live DB source
            //MockFAQSource(),
            //MockAnalyticsSource()
        ])
        return ChatOrchestrator(retriever: retriever)
    }

    // MARK: - Components
    private func bubble(text: String, role: ChatMessage.Role) -> some View {
        let isUser = (role == .user)
        return Text(text)
            .font(.system(size: textSize))
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
        guard !query.isEmpty, let orchestrator else { return }

        isLoading = true
        conversation.append(ChatMessage(role: .user, text: query, context: nil))
        prompt = ""

        Task {
            let answer = await orchestrator.answer(userQuery: query, personality: selectedPersonality, detailed: isDetailed)

            // Append the used context text at the end of the assistant's response for transparency.
            var contentWithContext = answer.content
            if !answer.usedContext.isEmpty {
                let contextBlock = answer.usedContext.enumerated()
                    .map { "\($0 + 1). \($1)" }
                    .joined(separator: "\n")
                contentWithContext += "\n\nContexto usado:\n" + contextBlock
            }

            let assistant = ChatMessage(role: .assistant, text: contentWithContext, context: answer.usedContext)
            await MainActor.run {
                self.conversation.append(assistant)
                self.isLoading = false
            }
        }
    }

    private func toggleTranscript() {
        if isRecording {
            speechRecognizer.stopTranscribing()
            isRecording = false
            let text = speechRecognizer.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                if prompt.isEmpty {
                    prompt = text
                } else {
                    prompt += (prompt.hasSuffix(" ") ? "" : " ") + text
                }
            }
            speechRecognizer.resetTranscript()
        } else {
            speechRecognizer.resetTranscript()
            speechRecognizer.startTranscribing()
            isRecording = true
        }
    }

    // MARK: - Persistence
    private func saveConversation() {
        do {
            let data = try JSONEncoder().encode(conversation)
            UserDefaults.standard.set(data, forKey: conversationStorageKey())
        } catch { }
    }

    private func loadConversation() {
        guard let data = UserDefaults.standard.data(forKey: conversationStorageKey()) else { return }
        do {
            conversation = try JSONDecoder().decode([ChatMessage].self, from: data)
        } catch { }
    }

    private func clearConversation() {
        conversation.removeAll()
        saveConversation()
        prompt = ""
    }

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                // Conversation view (oldest messages at the top, newest at the bottom)
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(conversation) { message in
                                HStack {
                                    if message.role == .assistant {
                                        bubble(text: message.text, role: .assistant)
                                        Spacer(minLength: 30)
                                    } else {
                                        Spacer(minLength: 30)
                                        bubble(text: message.text, role: .user)
                                    }
                                }
                                .padding(.horizontal)
                                .id(message.id)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .onAppear {
                        if orchestrator == nil { orchestrator = makeOrchestrator(context: modelContext) }
                        loadConversation()
                        scrollToBottom(proxy)
                    }
                    .onChange(of: conversation.count) { _, _ in
                        scrollToBottom(proxy)
                        saveConversation()
                    }
                }

                // Input area
                HStack(alignment: .bottom, spacing: 8) {
                    Button(action: toggleTranscript) {
                        Image(systemName: isRecording ? "stop.circle.fill" : "mic.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(isRecording ? .red : .primary)
                            .accessibilityLabel(isRecording ? "Detener grabación" : "Grabar voz")
                            .accessibilityHint("Dicta tu mensaje en español (México)")
                            .buttonSizing(.automatic)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .contentShape(Circle())

                    TextField("Escribe un mensaje...", text: $prompt, axis: .vertical)
                        .font(.system(size: textSize))
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3, reservesSpace: true)

                    Button(action: generate) {
                        if isLoading {
                            ProgressView().progressViewStyle(.circular)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 28, weight: .semibold))
                        }
                    }
                    .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            // Loading overlay
            if isLoading {
                Color.black.opacity(0.15).ignoresSafeArea()
                ProgressView("Generando respuesta...")
                    .padding(20)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                    .tint(.universalAccent)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    ChatSettingsView(
                        selectedPersonality: Binding(get: { selectedPersonality }, set: { selectedPersonality = $0 }),
                        isDetailed: $isDetailed,
                        textSize: $textSize,
                        onDeleteConversation: { clearConversation() }
                    )
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
    }
}

