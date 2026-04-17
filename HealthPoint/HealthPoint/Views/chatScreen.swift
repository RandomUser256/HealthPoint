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
            chatBackground
                .ignoresSafeArea()

            VStack(spacing: 12) {
                headerBar

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
            // Loading overlay
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
