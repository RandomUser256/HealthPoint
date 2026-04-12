//
//  MedicineExplorerViewModel.swift
//  HealthPoint
//
//  Created by Máximo on 4/11/26.
//

/*
import SwiftData
internal import Combine
import Foundation


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
    
    
    //private var user: UserModel?
    //@EnvironmentObject private var currentUser: UserSettings

    /*
    func setUser(_ user: User?) {
        self.user = user
        recompute()
    }
     */
    
    init(source: [Medicine], query: String, sortAscending: Bool, pageSize: Int, displayed: [Medicine], filterByUserPreferences: Bool) {
        self.source = source
        self.query = query
        self.sortAscending = sortAscending
        self.pageSize = pageSize
        self.displayed = displayed
        self.filterByUserPreferences = filterByUserPreferences
    }
    
    func buildLookupMaps(context: ModelContext) throws -> (
        medicines: [Int: Medicine],
        ingredients: [Int: Ingredient],
        effects: [Int: AdverseEffect]
    ) {
        let medicines = try context.fetch(FetchDescriptor<Medicine>())
        let ingredients = try context.fetch(FetchDescriptor<Ingredient>())
        let effects = try context.fetch(FetchDescriptor<AdverseEffect>())

        return (
            Dictionary(uniqueKeysWithValues: medicines.map { ($0.id, $0) }),
            Dictionary(uniqueKeysWithValues: ingredients.map { ($0.id, $0) }),
            Dictionary(uniqueKeysWithValues: effects.map { ($0.id, $0) })
        )
    }

    func loadFromStore(_ items: [Medicine]) {
        // Treat the fetched items as immutable source for this session
        self.source = items
        recompute()
    }

    func loadMoreIfNeeded(current item: Medicine?) {
        guard let item, let idx = displayed.firstIndex(where: { $0.id == item.id }) else { return }
        let threshold = displayed.count - 10
        if idx >= threshold { increasePage() }
    }

    func increasePage() {
        pageSize = min(pageSize + 50, source.count)
    }

    private func recompute() {
        var result = source
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            result = result.filter { med in
                med.getName().localizedCaseInsensitiveContains(trimmed) || med.getDescriptionText().localizedCaseInsensitiveContains(trimmed)
            }
        }
        if filterByUserPreferences {
            // Exclude medicines containing any of the user's ingredient allergies or unwanted medicines by name
            let allergySet = Set($currentUser.publicIngredientAllergies.map { $0.lowercased })
            let unwantedSet = Set($currentUser.publicUnwantedMedicine.map { $0.lowercased })
            result = result.filter { med in
                let medIngredients = Set(med.ingredients.map { $0.getName().lowercased() })
                
                //Checks if result contains allergic components. True if no value in common.
                let hasAllergy = !allergySet.isDisjoint(with: medIngredients)
                
                //
                let isUnwantedByName = unwantedSet.contains(med.name.lowercased())
                
                
                return !hasAllergy && !isUnwantedByName
            }
        }
        //Change sorting to ascending or descending
        result.sort { lhs, rhs in
            sortAscending ? lhs.getName().localizedCaseInsensitiveCompare(rhs.getName()) == .orderedAscending : lhs.getName().localizedCaseInsensitiveCompare(rhs.getName()) == .orderedDescending
        }
        // Apply paging
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
*/
