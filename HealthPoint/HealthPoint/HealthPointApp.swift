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

///Notes
///- Any model class with id=-1 had an invalid id in the original dataset

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
    @AppStorage("didPrepopulateStore") private var didPrepopulate: Bool = false
    @State private var isLoading: Bool = true
    @State private var loadingMessage: String = "Preparing data…"
    
    @State private var dataImporter: DataImportModel = DataImportModel()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            Ingredient.self,
            Medicine.self,
            AdverseEffect.self,
            User.self
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
                    LoadingView(progress: dataImporter)
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
    @ObservedObject var progress: DataImportModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text(progress.message)
                .font(.headline)
            
            ProgressView(value: progress.progress)
                .progressViewStyle(.linear)
            
            Text("\(Int(progress.progress * 100))%")
        }
        .padding()
    }
}

// MARK: - CSV Import Helpers
private extension HealthPointApp {
    func prepopulateIfNeeded() async {
        guard didPrepopulate else {
            // Already imported on a previous launch
            isLoading = false
            return
        }
        do {
            loadingMessage = "Importing medicines…"
            try await dataImporter.importMedicines()
            
            loadingMessage = "Importing ingredients…"
            try await dataImporter.importIngredients()
            
            loadingMessage = "Importing adverse effects…"
            try await dataImporter.importAdverseEffects()
            
            loadingMessage = "Linking medicine to ingredients…"
            try await dataImporter.linkMedicineIngredients()
            
            loadingMessage = "Linking medicine to adverse effects…"
            try await dataImporter.linkMedicineAdverseEffects()
            
            didPrepopulate = true
        } catch {
            // You may want to present an error UI and/or reset the store
            print("Prepopulation failed: \(error)")
        }
        isLoading = false
    }
}
