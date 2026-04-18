//
//  MedicineDetailView.swift
//  HealthPoint
//
//  Created by CETYS Universidad  on 15/04/26.
//
// Legacy standalone medicine detail implementation kept as reference after the inline detail redesign.
/*
import SwiftUI

//Expanded view when clicking on a medicine item
struct MedicineDetailView: View {
    //Medicine to display
    let medicine: Medicine
    
    @EnvironmentObject private var currentUser: UserSettings

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
                            HStack {
                                
                                Text(ing.getName())
                                
                                Button(action: {
                                    currentUser.user.publicIngredientAllergies.append(ing)
                                }) {
                                    if (currentUser.user.publicUnwantedMedicine.contains {$0.id == ing.id }) {
                                        Image(systemName: "checkmar.circle.fill")
                                    } else {
                                        Image(systemName: "plus")
                                    }
                                }
                            }
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
*/
