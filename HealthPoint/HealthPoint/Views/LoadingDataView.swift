//
//  LoadingDataView.swift
//  HealthPoint
//
//  Created by Máximo on 4/12/26.
//
// Archived loading prototype kept as reference from the original CSV import workflow.
/*
import SwiftUI

struct LoadingView: View {
    @ObservedObject var progress: DataImportModel
    var body: some View {
        VStack(spacing: 20) {
            Text(progress.message)
                .font(.headline)
            
            ProgressView(value: progress.progress)
                .progressViewStyle(.linear)
            
            Text("\(Int(progress.progress * 100))%")
        }
        .padding()
    }
    
    func importProgress() {
        progress.message = "Importing ingredients..."
        try await importIngredients()
        progress.currentStep += 1
        progress.progress = Double(progress.currentStep / progress.totalSteps)

        let totalRows = rows.count
        var processed = 0

        for row in rows {
            processed += 1
            
            if processed % 500 == 0 {
                progress.progress = Double(processed) / Double(totalRows)
            }
        }
    }
}
*/
