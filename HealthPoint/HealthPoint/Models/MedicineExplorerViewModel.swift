import SwiftUI
import SwiftData
import Foundation
internal import Combine

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
    
    //SwiftData related function and variable
    private var context: ModelContext!
    func setContext(_ context: ModelContext) { self.context = context }

    init() { }

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
        do {
            var fetch = FetchDescriptor<Medicine>(
                predicate: nil,
                sortBy: [SortDescriptor(\.normalizedName, order: sortAscending ? .forward : .reverse)],
            )
            fetch.fetchLimit = pageSize
            let items = try context.fetch(fetch)
            self.source = items
            self.displayed = items
        } catch {
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

    var sectioned: [(key: String, items: [Medicine])] {
        let groups = Dictionary(grouping: displayed) { med in
            String(med.getName().prefix(1)).uppercased()
        }
        return groups.keys.sorted().map { key in
            (key, groups[key]!.sorted { $0.getName().localizedCaseInsensitiveCompare($1.getName()) == .orderedAscending })
        }
    }
}
