import Foundation

enum ChatPersonality: String, CaseIterable, Identifiable {
    case friendly
    case expert
    case teacher
    case witty
    case concise

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .friendly: return "Friendly"
        case .expert: return "Expert"
        case .teacher: return "Teacher"
        case .witty: return "Witty"
        case .concise: return "Concise"
        }
    }

    var systemInstructions: String {
        switch self {
        case .friendly:
            return "You are a friendly, encouraging assistant. Be helpful and approachable while staying concise."
        case .expert:
            return "You are a domain expert. Provide precise, technically accurate answers, cite assumptions, and avoid unnecessary fluff."
        case .teacher:
            return "You are a patient teacher. Explain concepts step-by-step with simple examples and checks for understanding."
        case .witty:
            return "You are a witty assistant with a light touch of humor. Keep jokes tasteful and brief; never compromise accuracy."
        case .concise:
            return "You are a terse assistant. Answer in the fewest words necessary without losing correctness."
        }
    }
}
