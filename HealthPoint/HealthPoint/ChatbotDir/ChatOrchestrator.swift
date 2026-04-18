import Foundation
import FoundationModels

/// Orchestrates RAG-style answering: retrieves context, builds a prompt with personality, then queries the local model.
actor ChatOrchestrator {
    private let model = SystemLanguageModel.default
    private let retriever: KnowledgeRetriever

    init(retriever: KnowledgeRetriever) {
        self.retriever = retriever
    }

    /// Bundles the generated assistant response with the retrieval snippets used to ground it.
    struct Answer {
        let content: String
        let usedContext: [String]
    }

    /// Removes markdown markers so chat responses stay plain-text in the UI.
    private func sanitizeResponse(_ text: String) -> String {
        text
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "*", with: "")
    }

    /// Retrieves supporting context, builds the model prompt, and returns the assistant answer plus the snippets used.
    func answer(userQuery: String, personality: ChatPersonality, detailed: Bool) async -> Answer {
        guard model.availability == .available else {
            return Answer(content: "Apple Intelligence is not available on this device.", usedContext: [])
        }

        /// 1) Retrieve context
        let contextSnippets = await retriever.retrieveContext(for: userQuery)

        /// 2) Build instructions combining personality and retrieval guidance
        let verbosityInstruction = detailed
            ? "Provide a thorough, step-by-step explanation when helpful. Prefer complete details."
            : "Be concise. Prefer short, direct answers."

        let systemInstructions = await [
            personality.systemInstructions,
            "Use the provided CONTEXT when relevant. If information is missing, say so briefly.",
            "Cite data by referencing 'Context' rather than fabricating sources.",
            "Do not use markdown formatting. Do not surround words or key points with asterisks.",
            verbosityInstruction
        ].joined(separator: "\n\n")

        /// 3) Build a lightweight context preamble for the model
        let contextBlock: String
        if contextSnippets.isEmpty {
            contextBlock = "No external context available."
        } else {
            contextBlock = "Context:\n" + contextSnippets.enumerated().map { "\($0 + 1). \($1)" }.joined(separator: "\n")
        }

        let session = LanguageModelSession(instructions: systemInstructions)
        do {
            let compositePrompt = """
            User Query: \(userQuery)

            \(contextBlock)
            """
            let output = try await session.respond(to: compositePrompt)
            return Answer(content: sanitizeResponse(output.content), usedContext: contextSnippets)
        } catch {
            return Answer(content: "Error: \(error.localizedDescription)", usedContext: contextSnippets)
        }
    }
}
