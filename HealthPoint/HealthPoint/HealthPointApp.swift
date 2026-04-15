//
//  HealthPointApp.swift
//  HealthPoint
//
//  Created by Máximo Magallanes Urtuzuástegui on 10/04/26.
//

///TODO:
///- Check if app is not reloading data each boot up
///NEXT TODO NOW
///- Check if user is being saved correctly in the default.store
///     - Add option to swifth between stored users

///ERRORS:
/// - Paging is not working, all the medicine load at once
/// - When changing alphabetical order of listed items, the app does not load back to main list

///Notes
///- Any model class with id=-1 had an invalid id in the original dataset

import SwiftUI
import SwiftData
internal import Combine

//Structure for storing the user currently in session
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
    //Persisted storage indicator if dataset has previously been loaded
    @AppStorage("didPrepopulateStore") private var didPrepopulate: Bool = false
    @State private var isLoading: Bool = false
    
    //Message for debugging purposes
    @State private var loadingMessage: String = "Preparing data…"
    
    //Handles csv reading and maping to SwiftData objects
    //@State private var dataImporter: DataImportModel = DataImportModel()
    
    //Loads different SwiftData schema
    var sharedModelContainer: ModelContainer
    
    /*
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
    */
     
    var body: some Scene {
        WindowGroup {
            Group {
                //Loading progress var view for processing dataset
                if isLoading {
                    //LoadingView(progress: dataImporter)
                } else {
                    //main content view
                    ContentView()
                        .environmentObject(UserSettings())
                }
            }
            .task {
                //No longer loads data, uses a prebuilt default.store file
                //await prepopulateIfNeeded()
                
            }
        }
        .modelContainer(sharedModelContainer)
    }
     

    init() {
        preloadStoreIfNeeded()
        
        let fileManager = FileManager.default
        
        let appSupport = try! fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        
        let storeURL = appSupport.appendingPathComponent("default.store")

        let config = ModelConfiguration(url: storeURL)

        sharedModelContainer = try! ModelContainer(
            for: Item.self, Medicine.self, Ingredient.self, AdverseEffect.self, User.self,
            configurations: config
        )
        
        print("Disk storage path: ", URL.applicationSupportDirectory.path(percentEncoded: false))
        
        print(Bundle.main.bundlePath)
        
        let files = try? FileManager.default.contentsOfDirectory(atPath: Bundle.main.bundlePath)
        
        sharedModelContainer = try! ModelContainer(
            for: Medicine.self, Ingredient.self, AdverseEffect.self,
            configurations: ModelConfiguration()
        )
        
        print(files ?? [])
    }
}

// MARK: - Loading View progress bar
/* UNUSED with external DB import
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
 */

// MARK: - CSV Import Helpers
private extension HealthPointApp {
    //Calls importing functions for database
    /*
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
     */
}

func preloadStoreIfNeeded() {
    let fm = FileManager.default
    
    let appSupport = try! fm.url(
        for: .applicationSupportDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true
    )
    
    let storeURL = appSupport.appendingPathComponent("default.store")
    
    // If main file exists, assume all are present
    // ACTIVATE FOR FINAL VERSION!!!!!!!!
    guard !fm.fileExists(atPath: storeURL.path) else { return }
    
    let files = ["default.store", "default.store-wal", "default.store-shm"]
    
    for file in files {
        guard let src = Bundle.main.url(forResource: file, withExtension: nil) else {
            fatalError("Missing \(file)")
        }
        
        let dst = appSupport.appendingPathComponent(file)
        try! fm.copyItem(at: src, to: dst)
    }
}
