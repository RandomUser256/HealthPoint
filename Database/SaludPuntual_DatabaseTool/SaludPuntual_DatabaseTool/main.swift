//
//  main.swift
//  SaludPuntual_DatabaseTool
//
//  Created by Máximo on 4/13/26.
//
import SwiftData
import Foundation
internal import Combine

///WARNINGS
///Check working directory in "Edit Scheme" and place it to the root of this folder, so that the csv files can be opened
///Directory of generated files: /Users/usrName/Library/Application Support/

let importer = DataImportModel()
do {
    try await importer.runAll()
    print("Disk storage path: ", URL.applicationSupportDirectory.path(percentEncoded: false))
} catch {
    fputs("Import failed: \(error)\n", stderr)
    exit(1)
}
