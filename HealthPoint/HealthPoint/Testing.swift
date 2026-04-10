//
//  Testing.swift
//  
//
//  Created by CETYS Universidad  on 10/04/26.
//

import SwiftUI

@main
struct ChatbotProjectApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

import FoundationModels

struct AvailabilityView: View {
    
    private var model = SystemLanguageModel.default
    var body: some View {
        switch model.availability {
        case.available:
            ContentView()
        
        }
        Text("Hello, World!")
    }
}
