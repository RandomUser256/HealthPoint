//
//  MedicineModel.swift
//  HealthPoint
//
//  Created by Máximo on 4/11/26.
//

import SwiftData
import Foundation

// SwiftData model for a medicine entry (adjust fields to match your schema)
@Model
final class Medicine: Identifiable {
    @Attribute(.unique) var id: Int
    
    private var name: String
    //Version with no capitalization, for optimizing search up
    var normalizedName: String
    
    private var descriptionText: String
    
    /* MARKED ERRORS WHEN COMPILING
    var publicName: String {
        get { name }
        set {name = newValue}
    }
     */
    
    //Array to reference ingredients and adverseEffects related to this medicine
    @Relationship var ingredients: [Ingredient]
    @Relationship var adverseEffects: [AdverseEffect]
    
    //Used to link to a user if listed in allergy list
    //A single medicine can be linked to multiple users
    @Relationship var user: [User] = []

    init(id: Int, name: String, descriptionText: String = "") {
        self.id = id
        self.name = name
        self.normalizedName = name.lowercased()
        self.descriptionText = descriptionText
        self.ingredients = []
        self.adverseEffects = []
    }
    
    func getName() -> String {
        return name
    }
    
    func getDescriptionText() -> String {
        return descriptionText
    }
}
