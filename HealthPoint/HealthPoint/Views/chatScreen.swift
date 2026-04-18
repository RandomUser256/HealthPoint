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

/// Presents the pharmacy chat interface, manages transcript state, and bridges UI actions to the chat orchestrator.
struct chatScreen: View {
    // Used to call swiftData model actions
    @Environment(\.modelContext) private var modelContext

    // References global environmentObject of current user
    @EnvironmentObject var currentUser: UserSettings

    /// Current text waiting to be sent to the assistant.
    @State private var prompt = ""
    /// Tracks whether the assistant is currently generating a response.
    @State private var isLoading = false
    /// Selects which system prompt profile will shape the assistant's tone and constraints.
    @State private var selectedPersonality: ChatPersonality = .amaro
    /// Stores the visible conversation in chronological order for rendering and persistence.
    @State private var conversation: [ChatMessage] = [] // Oldest-first (top)
    /// Indicates whether live speech transcription is in progress.
    @State private var isRecording = false
    /// Switches between concise and more detailed assistant responses.
    @State private var isDetailed = false
    /// User-adjustable font size used for chat bubbles.
    @State private var textSize: Double = 17

    // Lazily built on first .onAppear so modelContext is available.
    @State private var orchestrator: ChatOrchestrator?

    /// Handles speech-to-text capture for voice input.
    @State var speechRecognizer = SpeechRecognizer()

    private let chatBackground = Color(.systemGroupedBackground)
    private let cardFill = Color(.foreground).opacity(0.4)

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
    /// Renders a single message bubble with styling based on whether it belongs to the user or assistant.
    private func bubble(text: String, role: ChatMessage.Role) -> some View {
        let isUser = (role == .user)
        return Text(text)
            .font(.system(size: textSize))
            .foregroundStyle(isUser ? .universalAccent : .black)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isUser ? Color(.background).opacity(0.55) : cardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color(.universalAccent).opacity(isUser ? 0.9 : 0.55), lineWidth: 1.5)
                    )
            )
            .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
            .accessibilityLabel("\(isUser ? "Tu mensaje" : "Respuesta del asistente"): \(text)")
    }

    /// Builds a reusable circular button for the input toolbar, optionally replacing the icon with a spinner.
    private func circularActionButton(systemName: String, label: String, isLoading: Bool = false) -> some View {
        ZStack {
            Circle()
                .fill(.universalAccent)
                .overlay(Circle().stroke(Color(.universalAccent), lineWidth: 1.5))

            if isLoading {
                ProgressView()
                    .tint(.green)
            } else {
                Image(systemName: systemName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.green)
            }
        }
        .frame(width: 58, height: 58)
        .accessibilityLabel(label)
    }

    private var inputContainer: some ShapeStyle {
        cardFill
    }

    /// Displays the screen title and links into the chat configuration controls.
    private var headerBar: some View {
        HStack {
            Text("Chat")
                .font(.largeTitle.bold())
                .foregroundStyle(.universalAccent)

            Spacer()

            NavigationLink {
                ChatSettingsView(
                    selectedPersonality: Binding(get: { selectedPersonality }, set: { selectedPersonality = $0 }),
                    isDetailed: $isDetailed,
                    textSize: $textSize,
                    onDeleteConversation: { clearConversation() }
                )
            } label: {
                VStack(spacing: 6) {
                    CircleIcon(systemName: "gearshape.fill", paddingSize: 16)
                    Text("Ajustes")
                        .font(.caption)
                        .foregroundStyle(.universalAccent)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Abrir ajustes del chat")
            .accessibilityHint("Muestra la configuración de personalidad, detalle y tamaño de texto")
        }
        .padding(.horizontal)
    }

    /// Keeps the newest message visible after loading or appending conversation entries.
    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        guard let lastID = conversation.last?.id else { return }
        withAnimation {
            proxy.scrollTo(lastID, anchor: .bottom)
        }
    }

    // MARK: - Actions
    /// Sends the current prompt to the orchestrator, appends both sides of the exchange, and captures retrieved context.
    private func generate() {
        let query = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, let orchestrator else { return }

        isLoading = true
        conversation.append(ChatMessage(role: .user, text: query, context: nil))
        prompt = ""

        Task {
            let answer = await orchestrator.answer(userQuery: query, personality: selectedPersonality, detailed: isDetailed)

            /// Append the used context text at the end of the assistant's response for transparency.
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

    /// Starts or stops voice transcription and merges the recognized text into the current prompt.
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
    /// Persists the current conversation locally under the active user's storage key.
    private func saveConversation() {
        do {
            let data = try JSONEncoder().encode(conversation)
            UserDefaults.standard.set(data, forKey: conversationStorageKey())
        } catch { }
    }

    /// Restores the last saved conversation for the active user, if one exists.
    private func loadConversation() {
        guard let data = UserDefaults.standard.data(forKey: conversationStorageKey()) else { return }
        do {
            conversation = try JSONDecoder().decode([ChatMessage].self, from: data)
        } catch { }
    }

    /// Clears both the on-screen conversation and its persisted copy.
    private func clearConversation() {
        conversation.removeAll()
        saveConversation()
        prompt = ""
    }

    var body: some View {
        ZStack {
            chatBackground
                .ignoresSafeArea()

            VStack(spacing: 12) {
                headerBar

                /// Conversation view (oldest messages at the top, newest at the bottom)
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

                /// Input area
                HStack(alignment: .bottom, spacing: 8) {
                    Button(action: toggleTranscript) {
                        circularActionButton(
                            systemName: isRecording ? "stop.fill" : "mic.fill",
                            label: isRecording ? "Detener grabación" : "Iniciar grabación"
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Dicta tu mensaje en español")

                    TextField("Escribe un mensaje...", text: $prompt, axis: .vertical)
                        .font(.system(size: textSize))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(inputContainer)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(Color(.universalAccent), lineWidth: 1.5)
                                )
                        )
                        .lineLimit(3, reservesSpace: true)
                        .foregroundStyle(.black)
                        .tint(.universalAccent)
                        .accessibilityLabel("Campo de mensaje")
                        .accessibilityHint("Escribe la consulta que quieres enviar")

                    Button(action: generate) {
                        circularActionButton(
                            systemName: "paperplane.fill",
                            label: "Enviar mensaje",
                            isLoading: isLoading
                        )
                    }
                    .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                    .buttonStyle(.plain)
                    .accessibilityHint("Envía tu mensaje al asistente")
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            /// Loading overlay
            if isLoading {
                Color.black.opacity(0.15).ignoresSafeArea()
                ProgressView("Generando respuesta...")
                    .padding(20)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                    .tint(.universalAccent)
            }
        }
        .navigationBarBackButtonHidden(false)
    }
}
