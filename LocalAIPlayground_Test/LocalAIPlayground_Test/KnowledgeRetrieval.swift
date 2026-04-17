import Foundation

// MARK: - Knowledge Source Protocol
protocol KnowledgeSource {
    /// A human-readable name for the source (for logging/observability)
    var name: String { get }

    /// Returns relevant context snippets for a user query.
    /// Implementations may query databases, perform vector similarity search, etc.
    func fetchRelevantContext(for query: String) async throws -> [String]
}

// MARK: - Mock Sources (replace with your DB integrations)
struct MockFAQSource: KnowledgeSource {
    let name = "FAQ"

    func fetchRelevantContext(for query: String) async throws -> [String] {
        // Simulate a small delay and return canned snippets.
        try await Task.sleep(nanoseconds: 150_000_000)
        let snippets = [
            "FAQ: Our service syncs data every 15 minutes by default.",
            "FAQ: You can export data as CSV or JSON from the dashboard.",
            "FAQ: Contact support at support@example.com for escalations."
        ]
        // Naive filtering: include snippets that contain any query word
        let tokens = Set(query.lowercased().split(separator: " "))
        let filtered = snippets.filter { snippet in
            let sTokens = Set(snippet.lowercased().split(separator: " "))
            return !tokens.isDisjoint(with: sTokens)
        }
        return filtered.isEmpty ? Array(snippets.prefix(1)) : filtered
    }
}

struct MockAnalyticsSource: KnowledgeSource {
    let name = "Analytics"

    func fetchRelevantContext(for query: String) async throws -> [String] {
        try await Task.sleep(nanoseconds: 120_000_000)
        // Pretend this came from a time-series DB aggregation
        return [
            "Analytics: DAU 42,315 (+3.2% WoW), MAU 128,004 (+1.1% WoW).",
            "Analytics: Conversion rate 4.7% (last 7 days). Top region: EU (38%)."
        ]
    }
}

// MARK: - Knowledge Retriever
actor KnowledgeRetriever {
    private let sources: [KnowledgeSource]

    init(sources: [KnowledgeSource]) {
        self.sources = sources
    }

    /// Fan-out to all sources in parallel and gather relevant snippets.
    func retrieveContext(for query: String) async -> [String] {
        await withTaskGroup(of: [String].self) { group in
            for source in sources {
                group.addTask {
                    do { return try await source.fetchRelevantContext(for: query) }
                    catch { return [] }
                }
            }

            var aggregated: [String] = []
            for await snippets in group {
                aggregated.append(contentsOf: snippets)
            }
            // Deduplicate and trim
            let unique = Array(Set(aggregated)).sorted()
            return unique
        }
    }
}
