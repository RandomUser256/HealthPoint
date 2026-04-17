import SwiftUI

public struct ChatSettingsView: View {
    @Binding var selectedPersonality: ChatPersonality
    @Binding public var isDetailed: Bool
    @Binding public var textSize: Double

    public var onDeleteConversation: () -> Void

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
        Form {
            Section(header: Text("Personalidad")) {
                Picker("Personalidad", selection: $selectedPersonality) {
                    ForEach(ChatPersonality.allCases) { persona in
                        Text(persona.displayName).tag(persona)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section(header: Text("Estilo de Respuesta")) {
                Toggle(isOn: $isDetailed) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Respuestas Detalladas")
                        Text("Apaga para respuestas concisas")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section(header: Text("Text Size"), footer: Text("Adjust the size of messages in the conversation")) {
                HStack {
                    Image(systemName: "textformat.size.smaller")
                    Slider(value: $textSize, in: 13...28, step: 1)
                    Image(systemName: "textformat.size.larger")
                }
                .accessibilityLabel("Tamaño de texto")
                .accessibilityValue("\(Int(textSize)) points")
            }
            
            Section {
                Button(role: .destructive) {
                    onDeleteConversation()
                } label: {
                    Label("Borrar Conversación", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Settings de Chat")
        .foregroundStyle(.universalAccent)
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
