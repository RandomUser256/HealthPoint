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

class DataInterface: ObservableObject {
    var medicinesByName: [String: Medicine] = [:]
    var ingredientsToMedicines: [String: [Medicine]] = [:]

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
    
    func ingredientNameSet(for medicine: Medicine) -> Set<String> {
        Set(medicine.ingredients.map { $0.getName().lowercased() })
    }
    
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
