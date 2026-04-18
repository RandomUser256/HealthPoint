import SwiftUI
import SwiftData
import Foundation
internal import Combine

/// Drives medicine search, sorting, paging, and preference-based filtering for the explorer screen.
@MainActor
final class MedicineExplorerViewModel: ObservableObject {
    /// Immutable cache of fetched results (treated as source snapshot)
    private var source: [Medicine] = []

    /// Paging and filters
    @Published var query: String = "" { didSet { recompute() } }
    @Published var sortAscending: Bool = true { didSet { recompute() } }
    @Published var pageSize: Int = 50 { didSet { recompute() } }
    @Published private(set) var displayed: [Medicine] = []

    /// User-based filters
    @Published var filterByUserPreferences: Bool = false { didSet { recompute() } }
    
    var currentUser: UserSettings?
    
    /// SwiftData related function and variable
    private var context: ModelContext!
    /// Injects the SwiftData context required for fetches and pagination.
    func setContext(_ context: ModelContext) { self.context = context }

    init() { }

    /// Builds an identifier-based lookup map for medicines currently stored on disk.
    func medicineLookupMap() throws -> [Int: Medicine] {
        let meds = try context.fetch(FetchDescriptor<Medicine>())
        return Dictionary(uniqueKeysWithValues: meds.map { ($0.id, $0) })
    }
    
    /// Seeds the view model with a pre-fetched snapshot and recomputes derived UI state.
    func loadFromStore(_ items: [Medicine]) {
        self.source = items
        recompute()
    }
    
    /// Loads the initial medicine page from SwiftData.
    func loadFromStore() {
        refreshFromStore()
    }

    /// Refetches the current page directly from storage, honoring the selected sort direction.
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

    /// Requests the next page when the list scroll approaches the end of the currently displayed items.
    func loadMoreIfNeeded(current item: Medicine?) {
        guard let item, let idx = displayed.firstIndex(where: { $0.id == item.id }) else { return }
        let threshold = displayed.count - 10
        if idx >= threshold { increasePage() }
    }

    /// Expands the page size and refetches enough results to extend infinite scrolling.
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

    /// Reapplies search, user preference filters, sorting, and page limits to the source snapshot.
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

    /// Groups the visible medicines by leading letter for sectioned list rendering.
    var sectioned: [(key: String, items: [Medicine])] {
        let groups = Dictionary(grouping: displayed) { med in
            String(med.getName().prefix(1)).uppercased()
        }
        let sortedKeys = groups.keys.sorted { lhs, rhs in
            sortAscending
                ? lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
                : lhs.localizedCaseInsensitiveCompare(rhs) == .orderedDescending
        }
        return sortedKeys.map { key in
            let items = groups[key]!.sorted { lhs, rhs in
                sortAscending
                    ? lhs.getName().localizedCaseInsensitiveCompare(rhs.getName()) == .orderedAscending
                    : lhs.getName().localizedCaseInsensitiveCompare(rhs.getName()) == .orderedDescending
            }
            return (key, items)
        }
    }
}
