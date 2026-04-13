//
//  ContentView.swift
//  HealthPoint
//
//  Created by Máximo Magallanes Urtuzuástegui on 10/04/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    //Used to call swiftData model actions
    @Environment(\.modelContext) private var modelContext
    
    //References global environmentObject of current user
    @EnvironmentObject var currentUser: UserSettings

    var body: some View {
        MedicineExplorer()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
