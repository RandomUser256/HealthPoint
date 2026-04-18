//
//  DataImportModel.swift
//  HealthPoint
//
//  Created by Máximo on 4/12/26.
//
// Legacy CSV import implementation kept as reference while the app uses a bundled prebuilt store.
/* UNUSED with external DB import
import SwiftData
import Foundation
internal import Combine

class DataImportModel: ObservableObject {
    @Published var data: [Data] = []
    
    //Variable for import progress tracking
    @Published var message: String = ""
    @Published var progress: Double = 0.0  // 0 → 1
    let totalSteps = 5.0  // ingredients, meds, effects, link1, link2
    var currentStep = 0.0
    
    //Indicates if importing has been previously done or not
    private var didPrepopulateStore: Bool = false
    
    //Stores SwiftData schema for persisted objects
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
    
    init() {
        
    }
    
    //Builds dictionaries of (key, item) for each object type. Speeds up lookups
    func buildLookupMaps(context: ModelContext) throws -> (
        medicines: [Int: Medicine],
        ingredients: [Int: Ingredient],
        effects: [Int: AdverseEffect]
    ) {
        //Fetches objects of each class type from disk
        let medicines = try context.fetch(FetchDescriptor<Medicine>())
        let ingredients = try context.fetch(FetchDescriptor<Ingredient>())
        let effects = try context.fetch(FetchDescriptor<AdverseEffect>())

        return (
            Dictionary(uniqueKeysWithValues: medicines.map { ($0.id, $0) }),
            Dictionary(uniqueKeysWithValues: ingredients.map { ($0.id, $0) }),
            Dictionary(uniqueKeysWithValues: effects.map { ($0.id, $0) })
        )
    }

    //Updates progress tracker indicators
    func importProgress() {
        if (currentStep >= 5) {
            return
        }
        
        currentStep += 1
        
        progress = currentStep*5
    }
    
    func linkMedicineIngredients() async throws {
        let context = sharedModelContainer.mainContext
        
        let maps = try buildLookupMaps(context: context)
        
        let rows = try readCSV(named: "medicine_ingredients")
        
        var batchCount = 0
        let batchSize = 500
        
        for row in rows {
            //Creates inmutable vraiables for target id (medicine and ingredient), extracts the corresponding object for each
            guard let medId = Int(row["rxnorm_id"] ?? ""),
                  let ingId = Int(row["rxnorm_id_ingredient"] ?? ""),
                  let medicine = maps.medicines[medId],
                  let ingredient = maps.ingredients[ingId]
            else { continue }
            
            // Avoid duplicates
            if !medicine.ingredients.contains(where: { $0.id == ingId }) {
                medicine.ingredients.append(ingredient)
            }
            
            //Indicator for loading batch, when module is cero then all entries have been processed
            batchCount += 1
            if batchCount % batchSize == 0 {
                //Saves changes to disk
                try context.save()
            }
        }
        
        try context.save()
        
        //Update loading progress
        importProgress()
    }
    
    func linkMedicineAdverseEffects() async throws {
        let context = sharedModelContainer.mainContext
        
        let maps = try buildLookupMaps(context: context)
        
        let rows = try readCSV(named: "medicine_adverse_effects")
        
        var batchCount = 0
        let batchSize = 500
        
        for row in rows {
            //Creates inmutable vraiables for target id (medicine and adverseEffect), extracts the corresponding object for each
            guard let medId = Int(row["rxnorm_id"] ?? ""),
                  let effId = Int(row["meddra_id"] ?? ""),
                  let medicine = maps.medicines[medId],
                  let effect = maps.effects[effId]
            else { continue }
            
            if !medicine.adverseEffects.contains(where: { $0.id == effId }) {
                medicine.adverseEffects.append(effect)
            }
            
            //Indicator for loading batch, when module is cero then all entries have been processed
            batchCount += 1
            if batchCount % batchSize == 0 {
                try context.save()
            }
        }
        
        try context.save()
        
        importProgress()
    }

    //Import object registries
    func importMedicines() async throws {
        let context = sharedModelContainer.mainContext
        //let rows = try streamCSV(named: "medicines") // medicines.csv in bundle
        
        var batchCount = 0
        let batchSize = 500  // tune this
        
        try streamCSV(named: "vocab_rxnorm_product") { row in
            let id = row["rxnorm_id"] ?? row.values.first ?? ""
            let numericId = Int(id)
            
            let name = row["rxnorm_name"] ?? ""
            let description = /*row["description"] ?? */ ""
            //let ingredients = row["ingredients"]?.split(separator: ";").map { String($0).trimmingCharacters(in: .whitespaces) } ?? []
            guard !name.isEmpty else { return }
            
            //let safeId: Int
            
            //guard let id = numericId, id >= 0 else { return }
            let safeId = (numericId ?? -1) >= 0 ? numericId! : -1
            
            //let med = Medicine(name: name, descriptionText: description, ingredients: ingredients)
            let med = Medicine(id: safeId, name: name, descriptionText: description)
            
            context.insert(med)
            
            batchCount += 1
            
            // Save in batches
            if batchCount % batchSize == 0 {
                try? context.save()
            }
        }
        try context.save()
        
        importProgress()
    }

    //Import object registries
    func importAdverseEffects() async throws {
        let context = sharedModelContainer.mainContext
        
        var batchCount = 0
        let batchSize = 500  // tune this
        
        try streamCSV(named: "vocab_meddra_adverse_effect") { row in
            
            let idStr = row["meddra_id"] ?? row.values.first ?? ""
            let numericId = Int(idStr)
            
            let name = row["meddra_name"] ?? row["name"] ?? ""
            let termType = row["meddra_term_type"] ?? ""
            
            guard !name.isEmpty else { return }
            
            let safeId = (numericId ?? -1) >= 0 ? numericId! : -1
            
            let effect = AdverseEffect(
                id: safeId,
                name: name,
                meddraTermType: termType
            )
            
            context.insert(effect)
            batchCount += 1
            
            // Save in batches
            if batchCount % batchSize == 0 {
                try? context.save()
            }
        }
        
        try context.save()
        
        importProgress()
    }
    
    //Import object registries
    func importIngredients() async throws {
        let context = sharedModelContainer.mainContext
        
        var batchCount = 0
        let batchSize = 500  // tune this
        
        try streamCSV(named: "vocab_rxnorm_ingredient") { row in
            let idStr = row["rxnorm_id"] ?? row.values.first ?? ""
            let numericId = Int(idStr)
            
            let name = row["rxnorm_name"] ?? row["name"] ?? ""
            
            guard !name.isEmpty else { return }
            
            let safeId = (numericId ?? -1) >= 0 ? numericId! : -1
            
            let effect = Ingredient(
                id: safeId,
                name: name
            )
            
            context.insert(effect)
            batchCount += 1
            
            // Save in batches
            if batchCount % batchSize == 0 {
                try? context.save()
            }
        }
        
        try context.save()
        
        importProgress()
    }
    
    // Minimal CSV reader that returns an array of dictionaries keyed by header names
    func readCSV(named resourceName: String) throws -> [[String: String]] {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "csv") else {
            throw NSError(domain: "CSV", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing \(resourceName).csv in bundle"]) }
        let data = try Data(contentsOf: url)
        guard let content = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "CSV", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to decode CSV \(resourceName)"]) }
        var lines = content.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
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
    
    // Minimal CSV reader that reads file in chunks, meant for extremely large files
    func streamCSV(
        named resourceName: String,
        rowHandler: (_ row: [String: String]) -> Void
    ) throws {
        
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "csv") else {
            throw NSError(domain: "CSV", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing file"])
        }
        
        let stream = InputStream(url: url)!
        stream.open()
        defer { stream.close() }
        
        let bufferSize = 4096
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        var leftover = ""
        var headers: [String] = []
        var isFirstLine = true
        
        while stream.hasBytesAvailable {
            let read = stream.read(&buffer, maxLength: bufferSize)
            if read <= 0 { break }
            
            let chunk = String(bytes: buffer[0..<read], encoding: .utf8) ?? ""
            let lines = (leftover + chunk).split(separator: "\n", omittingEmptySubsequences: false)
            
            leftover = String(lines.last ?? "")
            
            for line in lines.dropLast() {
                let lineStr = String(line)
                
                if isFirstLine {
                    headers = lineStr.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
                    isFirstLine = false
                    continue
                }
                
                let cols = splitCSVLine(lineStr)
                var dict: [String: String] = [:]
                
                for (i, h) in headers.enumerated() {
                    dict[h] = i < cols.count ? cols[i] : ""
                }
                
                rowHandler(dict)
            }
        }
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
*/
