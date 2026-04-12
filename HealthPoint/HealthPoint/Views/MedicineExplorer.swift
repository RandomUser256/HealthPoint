import SwiftUI
import SwiftData
import Foundation
internal import Combine

/// TODO:
/// - Add safeguards for when a user is not selected and filtering is to be applied


// View model derives dynamic content, keeps source immutable via fetched cache
@MainActor
final class MedicineExplorerViewModel: ObservableObject {
    // Immutable cache of fetched results (treated as source snapshot)
    private var source: [Medicine] = []

    // Paging and filters
    @Published var query: String = "" { didSet { recompute() } }
    @Published var sortAscending: Bool = true { didSet { recompute() } }
    @Published var pageSize: Int = 50 { didSet { recompute() } }
    @Published private(set) var displayed: [Medicine] = []

    // User-based filters
    @Published var filterByUserPreferences: Bool = false { didSet { recompute() } }
    
    var currentUser: UserSettings?
    
    private var context: ModelContext!

    func setContext(_ context: ModelContext) { self.context = context }

    init() {}

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
            // Update displayed with first page based on current query/sort
            let descriptor = FetchDescriptor<Medicine>()
            let total = try context.fetchCount(descriptor)
            // Fetch first page
            var fetch = FetchDescriptor<Medicine>(
                predicate: nil,
                sortBy: [SortDescriptor(\.normalizedName, order: sortAscending ? .forward : .reverse)],
            )
            fetch.fetchLimit = pageSize
            let items = try context.fetch(fetch)
            self.source = items
            self.displayed = items
            // We don't store total here; the view will compute and pass it
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
        let newSize = min(pageSize + 50, (try? context.fetchCount(FetchDescriptor<Medicine>())) ?? pageSize)
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
        displayed = Array(result.prefix(pageSize))
    }

    // Sectioning by first letter of name
    var sectioned: [(key: String, items: [Medicine])] {
        let groups = Dictionary(grouping: displayed) { med in
            String(med.getName().prefix(1)).uppercased()
        }
        return groups.keys.sorted().map { key in
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
                if model.sectioned.isEmpty {
                    ContentUnavailableView("No results", systemImage: "pills", description: Text("Try adjusting your search or filters."))
                } else {
                    List {
                        ForEach(model.sectioned, id: \.key) { section in
                            Section(section.key) {
                                ForEach(section.items) { item in
                                    NavigationLink(value: item) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.getName())
                                                .font(.headline)
                                            Text(item.getDescriptionText())
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(2)
                                        }
                                        .task {
                                            model.loadMoreIfNeeded(current: item)
                                        }
                                    }
                                }
                            }
                        }
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
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Picker("Sort order", selection: $model.sortAscending) {
                            Text("Name A–Z").tag(true)
                            Text("Name Z–A").tag(false)
                        }
                        .pickerStyle(.inline)
                        Toggle(isOn: $model.filterByUserPreferences) {
                            Label("Respect user allergies & unwanted", systemImage: "line.3.horizontal.decrease.circle")
                        }
                    } label: {
                        Label("Filters", systemImage: "arrow.up.arrow.down.circle")
                    }
                }
            }
            .onAppear {
                model.setContext(modelContext)
                model.currentUser = currentUser
                model.loadFromStore()
                let descriptor = FetchDescriptor<Medicine>()
                allMedicines = (try? modelContext.fetchCount(descriptor)) ?? 0
            }
            .onChange(of: allMedicines) { _, _ in
                model.loadFromStore()
            }
            .navigationDestination(for: Medicine.self) { medicine in
                MedicineDetailView(medicine: medicine)
            }
        }
    }
}

struct MedicineDetailView: View {
    let medicine: Medicine

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(medicine.getName())
                    .font(.largeTitle.bold())
                Text(medicine.getDescriptionText())
                    .font(.body)
                if !medicine.ingredients.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ingredients").font(.headline)
                        ForEach(medicine.ingredients, id: \.self) { ing in
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
