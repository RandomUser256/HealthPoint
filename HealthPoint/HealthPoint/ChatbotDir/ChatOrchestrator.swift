import Foundation
import FoundationModels

/// Orchestrates RAG-style answering: retrieves context, builds a prompt with personality, then queries the local model.
actor ChatOrchestrator {
    private let model = SystemLanguageModel.default
    private let retriever: KnowledgeRetriever

    init(retriever: KnowledgeRetriever) {
        self.retriever = retriever
    }

    struct Answer {
        let content: String
        let usedContext: [String]
    }

    func answer(userQuery: String, personality: ChatPersonality) async -> Answer {
        guard model.availability == .available else {
            return Answer(content: "Apple Intelligence is not available on this device.", usedContext: [])
        }

        // 1) Retrieve context
        let contextSnippets = await retriever.retrieveContext(for: userQuery)

        // 2) Build instructions combining personality and retrieval guidance
        let systemInstructions = await [
            personality.systemInstructions,
            "Use the provided CONTEXT when relevant. If information is missing, say so briefly.",
            "Cite data by referencing 'Context' rather than fabricating sources.",
        ].joined(separator: "\n\n")

        // 3) Build a lightweight context preamble for the model
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
            return Answer(content: output.content, usedContext: contextSnippets)
        } catch {
            return Answer(content: "Error: \(error.localizedDescription)", usedContext: contextSnippets)
        }
    }
}
