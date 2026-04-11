
import FoundationModels
import Foundation
import Combine

@MainActor
class ViewModel: ObservableObject {
    @Published var userInput = ""
    @Published var output = ""
    @Published var isProcessing = false
    @Published var errorMessage: String?

    private let model = SystemLanguageModel.default

    func runModel() async {
        guard model.isAvailable else {
            errorMessage = "Model not available on this device"
            return
        }

        isProcessing = true
        errorMessage = nil

        let prompt = userInput.isEmpty ? "Hello!" : userInput
        let session = LanguageModelSession()

        do {
            let response = try await session.respond(to: prompt)
            output = response.content
        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessing = false
    }

}
