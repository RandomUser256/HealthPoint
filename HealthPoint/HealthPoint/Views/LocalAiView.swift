//
//  LocalAiView.swift
//  HealthPoint
//
//  Created by Máximo on 4/11/26.
//
/*
import SwiftUI
import FoundationModels

struct LocalAiView: View {
    @State private var localPrompt = "Hello, how are you?"
    @State private var response = ""
    
    private let model = SystemLanguageModel.default
    
    
    
    var body: some View {
        VStack {
            Text("Local Ai model test")
            
            TextField ("Enter your prompt", text: $localPrompt)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
            
            Button("Generate response") {
                Task {
                    guard model.availability == .available else {
                        response = "Foundation model not available"
                        return
                    }
                    
                    let session = LanguageModelSession (
                        instructions: "You are a firnedly assistant"
                    )
                    
                    do {
                        let output = try await session.respond(to: localPrompt)
                        response = output.content
                    }
                    catch {
                        response = "Error: \(error.localizedDescription)"
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            
            ScrollView {
                Text(response)
                    .padding()
            }
        }
    }
}
*/
