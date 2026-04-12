//
//  IngredientModel.swift
//  HealthPoint
//
//  Created by Máximo on 4/11/26.
//

import SwiftData
import Foundation

@Model
class Ingredient: Identifiable {
    @Attribute(.unique) var id: Int
    
    private var name: String
    var normalizedName: String
    
    @Relationship(inverse: \Medicine.ingredients)
    private var medicines: [Medicine] = []
    
    //Used to link to a user if listed in allergy list
    //A single ingredient can be linked to multiple users
    @Relationship var user: [User] = []
    
    init(id: Int, name: String, medicines: [Medicine] = []) {
        self.id = id
        self.name = name
        self.normalizedName = name.lowercased()
        self.medicines = medicines
    }
    
    func getName() -> String {
        return name
    }
}
