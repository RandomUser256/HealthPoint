import SwiftUI

/// Presents chat-specific controls such as persona, response verbosity, text size, and transcript deletion.
public struct ChatSettingsView: View {
    @Binding var selectedPersonality: ChatPersonality
    @Binding public var isDetailed: Bool
    @Binding public var textSize: Double

    public var onDeleteConversation: () -> Void

    /// Accepts external bindings so changes made here update the active chat screen immediately.
    init(
        selectedPersonality: Binding<ChatPersonality>,
        isDetailed: Binding<Bool>,
        textSize: Binding<Double>,
        onDeleteConversation: @escaping () -> Void
    ) {
        self._selectedPersonality = selectedPersonality
        self._isDetailed = isDetailed
        self._textSize = textSize
        self.onDeleteConversation = onDeleteConversation
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack  {
                    title
                        .frame(alignment: .leading)
                    Spacer()
                    header
                        .frame(alignment: .trailing)
                }
                personalityCard
                responseStyleCard
                textSizeCard
                deleteButton
            }
            .padding()
        }
        .background(Color(.background).opacity(0.4))
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Renders the decorative header row for the settings screen.
    private var header: some View {
        HStack {
            CircleIcon(systemName: "bubble.left.and.bubble.right.fill")
            Spacer()
            //CircleIcon(systemName: "slider.horizontal.3")
        }
    }

    /// Displays the main title for the chat settings screen.
    private var title: some View {
        Text("Ajustes del chat")
            .font(.largeTitle)
            .bold()
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(.universalAccent)
            .fixedSize(horizontal: true, vertical: true)

    }

    /// Lets the user choose which assistant persona drives the system prompt.
    private var personalityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personalidad")
                .font(.headline)
                .foregroundStyle(.universalAccent)

            Picker("Personalidad", selection: $selectedPersonality) {
                ForEach(ChatPersonality.allCases) { persona in
                    Text(persona.displayName).tag(persona)
                }
            }
            .pickerStyle(.segmented)
            .tint(.universalAccent)
            .accessibilityLabel("Seleccionar personalidad")
        }
        .padding()
        .background(cardBackground)
    }

    /// Lets the user toggle between concise and detailed responses.
    private var responseStyleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Estilo de respuesta")
                .font(.headline)
                .foregroundStyle(.universalAccent)

            Toggle(isOn: $isDetailed) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Respuestas detalladas")
                        .foregroundStyle(.black)
                    Text("Apaga esta opción para respuestas más concisas.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(.universalAccent)
            .accessibilityLabel("Respuestas detalladas")
            .accessibilityHint("Activa o desactiva las respuestas extensas del asistente")
        }
        .padding()
        .background(cardBackground)
    }

    /// Adjusts the font size used when rendering the conversation transcript.
    private var textSizeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tamaño del texto")
                .font(.headline)
                .foregroundStyle(.universalAccent)

            HStack(spacing: 12) {
                Image(systemName: "textformat.size.smaller")
                    .foregroundStyle(.universalAccent)

                Slider(value: $textSize, in: 13...28, step: 1)
                    .tint(.universalAccent)

                Image(systemName: "textformat.size.larger")
                    .foregroundStyle(.universalAccent)
            }
            .accessibilityLabel("Tamaño de texto")
            .accessibilityValue("\(Int(textSize)) puntos")

            Text("Ajusta el tamaño de los mensajes en la conversación.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(cardBackground)
    }

    /// Exposes a destructive action that clears the saved conversation history.
    private var deleteButton: some View {
        Button(role: .destructive) {
            onDeleteConversation()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "trash.fill")
                    .foregroundStyle(.green)
                    .padding(25)
                    .background(.universalAccent)
                    .clipShape(Circle())

                Text("Borrar chat")
                    .font(.subheadline)
                    .foregroundStyle(.universalAccent)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Borrar conversación")
        .accessibilityHint("Elimina todo el historial del chat actual")
    }

    /// Provides a consistent card treatment shared across all settings sections.
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.background).opacity(0.5))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.universalAccent).opacity(0.8))
            )
    }
}

struct ChatSettingsView_Previews: PreviewProvider {
    @State static var personality: ChatPersonality = .amaro
    @State static var detailed: Bool = false
    @State static var size: Double = 17

    static var previews: some View {
        NavigationStack {
            ChatSettingsView(
                selectedPersonality: $personality,
                isDetailed: $detailed,
                textSize: $size,
                onDeleteConversation: {}
            )
        }
    }
}
