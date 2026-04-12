//
//  HealthPointApp.swift
//  HealthPoint
//
//  Created by Máximo Magallanes Urtuzuástegui on 10/04/26.
//

///TODO:
///- Attend vulnerabilities in MedicineExplorer view
///- Add corresponding 3 csv files so the app can populate local database
///- Correct readCSV() function to be safeguarded for extremely large csv files

import SwiftUI
import SwiftData
internal import Combine

class UserSettings: ObservableObject {
    @Published var user: User
    
    init(user: User) {
        self.user = user
    }
    
    init () {
        self.user = User()
    }
}

@main
struct HealthPointApp: App {
    @AppStorage("didPrepopulateStore") private var didPrepopulateStore: Bool = false
    @State private var isLoading: Bool = true
    @State private var loadingMessage: String = "Preparing data…"

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            Ingredient.self,
            Medicine.self,
            AdverseEffect.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if isLoading {
                    LoadingView(message: loadingMessage)
                } else {
                    ContentView()
                        .environmentObject(UserSettings())
                }
            }
            .task {
                await prepopulateIfNeeded()
            }
        }
        .modelContainer(sharedModelContainer)
    }

    init() {
        print("Disk storage path: ", URL.applicationSupportDirectory.path(percentEncoded: false))
    }
}

// MARK: - Loading View
private struct LoadingView: View {
    let message: String
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - CSV Import Helpers
private extension HealthPointApp {
    func prepopulateIfNeeded() async {
        guard !didPrepopulateStore else {
            // Already imported on a previous launch
            isLoading = false
            return
        }
        do {
            loadingMessage = "Importing ingredients…"
            try await importIngredients()
            loadingMessage = "Importing medicines…"
            try await importMedicines()
            loadingMessage = "Importing adverse effects…"
            try await importAdverseEffects()
            didPrepopulateStore = true
        } catch {
            // You may want to present an error UI and/or reset the store
            print("Prepopulation failed: \(error)")
        }
        isLoading = false
    }

    func importIngredients() async throws {
        let context = sharedModelContainer.mainContext
        let rows = try readCSV(named: "ingredients") // ingredients.csv in bundle
        for row in rows {
            // Adjust indices/keys to your CSV format
            let name = row["name"] ?? row.values.first ?? ""
            if name.isEmpty { continue }
            let ingredient = Ingredient(name: name)
            context.insert(ingredient)
        }
        try context.save()
    }

    func importMedicines() async throws {
        let context = sharedModelContainer.mainContext
        let rows = try readCSV(named: "medicines") // medicines.csv in bundle
        for row in rows {
            let name = row["name"] ?? ""
            let description = row["description"] ?? ""
            //let ingredients = row["ingredients"]?.split(separator: ";").map { String($0).trimmingCharacters(in: .whitespaces) } ?? []
            if name.isEmpty { continue }
            
            
            //let med = Medicine(name: name, descriptionText: description, ingredients: ingredients)
            let med = Medicine(name: name, descriptionText: description)
            
            context.insert(med)
        }
        try context.save()
    }

    func importAdverseEffects() async throws {
        let context = sharedModelContainer.mainContext
        let rows = try readCSV(named: "adverse_effects") // adverse_effects.csv in bundle
        for row in rows {
            let name = row["title"] ?? row["name"] ?? ""
            let meddraTermType = row["severity"] ?? ""
            if name.isEmpty { continue }
            let effect = AdverseEffect(name: name, meddraTermType: meddraTermType)
            context.insert(effect)
        }
        try context.save()
    }

    // Minimal CSV reader that returns an array of dictionaries keyed by header names
    func readCSV(named resourceName: String) throws -> [[String: String]] {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "csv") else {
            throw NSError(domain: "CSV", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing \(resourceName).csv in bundle"]) }
        let data = try Data(contentsOf: url)
        guard let content = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "CSV", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to decode CSV \(resourceName)"]) }
        var lines = content.split(whereSeparator: \n\r.contains).map(String.init)
        guard let headerLine = lines.first else { return [] }
        let headers = headerLine.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        lines.removeFirst()
        var rows: [[String: String]] = []
        for line in lines where !line.trimmingCharacters(in: .whitespaces).isEmpty {
            let cols = splitCSVLine(line)
            var dict: [String: String] = [:]
            for (i, h) in headers.enumerated() {
                dict[h] = i < cols.count ? cols[i] : ""
            }
            rows.append(dict)
        }
        return rows
    }

    // Basic CSV splitting that handles quoted commas
    func splitCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        for char in line {
            if char == "\"" { inQuotes.toggle(); continue }
            if char == "," && !inQuotes {
                result.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
                current.removeAll(keepingCapacity: true)
            } else {
                current.append(char)
            }
        }
        result.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
        return result
    }
}
