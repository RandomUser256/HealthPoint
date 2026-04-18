//
//  ChatBotDataInterface.swift
//  HealthPoint
//
//  Created by Máximo on 4/12/26.
//
import SwiftData
import Foundation
internal import Combine

//CURRENTLY NONE FUNCTIONAL

/// Builds lightweight lookup tables that help the chatbot reason over medicines and ingredient relationships.
class DataInterface: ObservableObject {
    var medicinesByName: [String: Medicine] = [:]
    var ingredientsToMedicines: [String: [Medicine]] = [:]

    /// Loads medicines from SwiftData and indexes them by medicine name and ingredient name.
    func buildIndex(context: ModelContext) throws -> DataInterface {
        let index = DataInterface()
        
        let meds = try context.fetch(FetchDescriptor<Medicine>())
        
        for med in meds {
            index.medicinesByName[med.normalizedName] = med
            
            for ingredient in med.ingredients {
                let key = ingredient.getName().lowercased()
                index.ingredientsToMedicines[key, default: []].append(med)
            }
        }
        
        return index
    }
    
    /// Extracts a normalized ingredient set for quick comparisons against user constraints.
    func ingredientNameSet(for medicine: Medicine) -> Set<String> {
        Set(medicine.ingredients.map { $0.getName().lowercased() })
    }
    
    /// Returns whether the medicine avoids every ingredient listed in the user's allergy set.
    func isMedicineSafe(
        medicine: Medicine,
        userAllergies: Set<String>
    ) -> Bool {
        let medIngredients = Set(
            medicine.ingredients.map { $0.getName().lowercased() }
        )
        
        return medIngredients.isDisjoint(with: userAllergies)
    }
}
