import SwiftUI
import SwiftData
import Foundation
internal import Combine

/// TODO:
/// - Add safeguards for when a user is not selected and filtering is to be applied
/// - Paging cumulatively adds new medicines to query, change so that it creates limited pages


// View model derives dynamic content, keeps source immutable via fetched cache
@MainActor
final class MedicineExplorerViewModel: ObservableObject {
    // Immutable cache of fetched results (treated as source snapshot)
    private var source: [Medicine] = []

    // Paging and filters
    
    //Specific query for filtering results, starts out blank. If value changes, it executes recompute()
    @Published var query: String = "" { didSet { recompute() } }
    @Published var sortAscending: Bool = true { didSet { recompute() } }
    @Published var pageSize: Int = 50 { didSet { recompute() } }
    @Published private(set) var displayed: [Medicine] = []

    // User-based filters
    @Published var filterByUserPreferences: Bool = false { didSet { recompute() } }
    
    var currentUser: UserSettings?
    
    //SwiftData related function and variable
    private var context: ModelContext!
    func setContext(_ context: ModelContext) { self.context = context }

    init() {
        
    }

    //Creates map linking Medicine objects with their id in a dictionary. Speeds up lookup
    func medicineLookupMap() throws -> [Int: Medicine] {
        let meds = try context.fetch(FetchDescriptor<Medicine>())
        return Dictionary(uniqueKeysWithValues: meds.map { ($0.id, $0) })
    }
    
    
    func loadFromStore(_ items: [Medicine]) {
        self.source = items
        recompute()
    }
    
    func loadFromStore() {
        refreshFromStore()
    }

    func refreshFromStore() {
        // Load the full source snapshot lazily via paged fetches; we keep only displayed items
        do {
            // Fetch request only for the specified amount of medicine registries
            var fetch = FetchDescriptor<Medicine>(
                predicate: nil,
                sortBy: [SortDescriptor(\.normalizedName, order: sortAscending ? .forward : .reverse)],
            )
            fetch.fetchLimit = pageSize
            
            //Total count of registered medicine objects
            //let _ = try context.fetchCount(fetch)
            
            //Fetches items from disk storage
            let items = try context.fetch(fetch)
            
            //Stores queried objects into medicine object array
            self.source = items
            
            //Transfers registries to the displayed array
            self.displayed = items
        } catch {
            // In case of fetch errors, clear displayed
            self.displayed = []
            self.source = []
        }
    }

    
    func loadMoreIfNeeded(current item: Medicine?) {
        guard let item, let idx = displayed.firstIndex(where: { $0.id == item.id }) else { return }
        let threshold = displayed.count - 10
        if idx >= threshold { increasePage() }
    }

    
    func increasePage() {
        //Increases pageSize indicator by 50, compares minimum value to avoid surpassing total amount of registered medicine
        let newSize = min(pageSize + 50, (try? context.fetchCount(FetchDescriptor<Medicine>())) ?? pageSize)
        
        //Stores the new page size
        pageSize = newSize
        
        // Fetch up to newSize
        do {
            var fetch = FetchDescriptor<Medicine>(
                predicate: nil,
                sortBy: [SortDescriptor(\.normalizedName, order: sortAscending ? .forward : .reverse)],
            )
            fetch.fetchLimit = pageSize
            let items = try context.fetch(fetch)
            self.source = items
            recompute()
        } catch {
            // ignore errors
        }
    }

    private func recompute() {
        //Stores current list of queried objects
        var result = source
        
        
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        
        if !trimmed.isEmpty {
            result = result.filter { med in
                med.getName().localizedCaseInsensitiveContains(trimmed) || med.getDescriptionText().localizedCaseInsensitiveContains(trimmed)
            }
        }
        if filterByUserPreferences, let currentUser {
            let allergySet = Set(currentUser.user.publicIngredientAllergies.map { $0.getName().lowercased() })
            let unwantedSet = Set(currentUser.user.publicUnwantedMedicine.map { $0.getName().lowercased() })
            result = result.filter { med in
                let medIngredients = Set(med.ingredients.map { $0.getName().lowercased() })
                let hasAllergy = !allergySet.isDisjoint(with: medIngredients)
                let isUnwantedByName = unwantedSet.contains(med.getName().lowercased())
                return !hasAllergy && !isUnwantedByName
            }
        }
        
        result.sort { lhs, rhs in
            sortAscending ? lhs.getName().localizedCaseInsensitiveCompare(rhs.getName()) == .orderedAscending : lhs.getName().localizedCaseInsensitiveCompare(rhs.getName()) == .orderedDescending
        }
        //Passes filtered results to displayed array
        displayed = Array(result.prefix(pageSize))
    }

    // Variable that holds array's of Medicine linked to a "key"
    var sectioned: [(key: String, items: [Medicine])] {
        //Groups items in "displayed" based in their first name letter
        let groups = Dictionary(grouping: displayed) { med in
            //Extracts initial character of medicine name
            String(med.getName().prefix(1)).uppercased()
        }
        //Returns an array of medicine keys ordered considering name lexical order
        return groups.keys.sorted().map { key in
            //returns "key" grouped elements, where elements in each group are lexically ordered in ascending order
            (key, groups[key]!.sorted { $0.getName().localizedCaseInsensitiveCompare($1.getName()) == .orderedAscending })
        }
    }
}

struct MedicineExplorer: View {
    @Environment(\.modelContext) private var modelContext
    
    @EnvironmentObject private var currentUser: UserSettings
    
    @StateObject private var model = MedicineExplorerViewModel()
    
    @State private var allMedicines: Int = 0

    var body: some View {
        NavigationStack {
            Group {
                //When no registered medicines
                if model.sectioned.isEmpty {
                    ContentUnavailableView("No results", systemImage: "pills", description: Text("Try adjusting your search or filters."))
                } else {
                    List {
                        //Cycles medicine array's contained in each "sectioned" entry
                        ForEach(model.sectioned, id: \.key) { section in
                            //Creates list UI section
                            Section(section.key) {
                                ForEach(section.items) { item in
                                    //Navigation link that displays new elements when preseed
                                    NavigationLink(value: item) {
                                        //Displayed elements in list rows
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.getName())
                                                .font(.headline)
                                            Text(item.getDescriptionText())
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(2)
                                        }
                                        //Calls load more task if end of list is reached
                                        .task {
                                            model.loadMoreIfNeeded(current: item)
                                        }
                                    }
                                }
                            }
                        }
                        //Shows bottom progress bar for loading new elements if applicable
                        if model.displayed.count < allMedicines {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .onAppear { model.increasePage() }
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Explore Medicines")
            .searchable(text: $model.query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search medicines")
            .toolbar {
                //Holds filtering actions for list view
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        //Dropdown menu for filters
                        Picker("Sort order", selection: $model.sortAscending) {
                            Text("Name A–Z").tag(true)
                            Text("Name Z–A").tag(false)
                        }
                        .pickerStyle(.inline)
                        //Toggles "filterByUserPreferences" variable
                        Toggle(isOn: $model.filterByUserPreferences) {
                            Label("Respect user allergies & unwanted", systemImage: "line.3.horizontal.decrease.circle")
                        }
                    } label: {
                        Label("Filters", systemImage: "arrow.up.arrow.down.circle")
                    }
                }
            }
            //Actions when view is rendered and/or re-rendered
            .onAppear {
                model.setContext(modelContext)
                
                //Updates current user of MedicineExplorerViewModel, which is in charge of fetching listed items
                model.currentUser = currentUser
                
                //Load items
                model.loadFromStore()
                
                //Fetches total count of registered medicine
                let descriptor = FetchDescriptor<Medicine>()
                allMedicines = (try? modelContext.fetchCount(descriptor)) ?? 0
            }
            .onChange(of: allMedicines) { _, _ in
                //Reload items if total amount of medicine is changed
                model.loadFromStore()
            }
            //For each list item, sets the destination when clicked
            .navigationDestination(for: Medicine.self) { medicine in
                MedicineDetailView(medicine: medicine)
            }
        }
    }
}

//Expanded view when clicking on a medicine item
//MAYBE EXTRACT INTO SEPARATE VIEW FILE
struct MedicineDetailView: View {
    //Medicine to display
    let medicine: Medicine

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(medicine.getName())
                    .font(.largeTitle.bold())
                Text(medicine.getDescriptionText())
                    .font(.body)
                //Cicles through listed ingredients
                //CURRENTLY NOT WORKING, ALWAYS SHOWS UP AS EMPTY LIST
                if !medicine.ingredients.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ingredients").font(.headline)
                        ForEach(medicine.ingredients, id: \.self) { ing in
                            Text(ing.getName())
                        }
                    }
                }
                Spacer(minLength: 0)
                if !medicine.adverseEffects.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Side effects").font(.headline)
                        ForEach(medicine.adverseEffects, id: \.self) { ing in
                            Text(ing.getName())
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .padding()
        }
        .navigationTitle(medicine.getName())
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    // Preview without a user
    MedicineExplorer()
}
