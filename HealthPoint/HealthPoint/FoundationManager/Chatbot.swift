//
//  ChatView.swift
//  
//
//  Created by CETYS Universidad  on 10/04/26.
//


import FoundationModels

struct ChatView: View {
    @State private var session = LanguageModelSession {
        "You are a friendly health coach."
    }
    @State private var responseText = ""

    func sendMessage(_ input: String) async {
        do {
            let response = try await session.respond(to: input)
            self.responseText = response.content
        } catch {
            print("Error: \(error)")
        }
    }
}
