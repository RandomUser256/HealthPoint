//
//  UserView.swift
//  HealthPoint
//
//  Created by CETYS Universidad  on 14/04/26.
//
import SwiftUI
import SwiftData

struct SearchableDropdownMenu: View {
  @State private var isExpanded = false
  @State private var selectedOption = "Select an Option"
  @State private var searchText = ""
  @Binding var options: [String]
  
  init(options: Binding<[String]>, isExpanded: Bool = false, selectedOption: String = "Select an Option", searchText: String = "") {
    self._options = options
    self.isExpanded = isExpanded
    self.selectedOption = selectedOption
    self.searchText = searchText
  }
  
  var filteredOptions: [String] {
    if searchText.isEmpty {
      return options
    } else {
      return options.filter { $0.lowercased().contains(searchText.lowercased()) }
    }
  }

  var body: some View {
    VStack {
      Button(action: { isExpanded.toggle() }) {
        HStack {
          Text(selectedOption)
          Spacer()
          Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
      }

      if isExpanded {
        VStack {
          TextField("Search...", text: $searchText)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()
          
          HStack {
            Spacer()
            Button {
              let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
              guard !trimmed.isEmpty, !options.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) else { return }
              options.append(trimmed)
              selectedOption = trimmed
              searchText = ""
              isExpanded = false
            } label: {
              Label("Add \"\(searchText)\"", systemImage: "plus.circle.fill")
                .labelStyle(.titleAndIcon)
            }
            .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
          }
          .padding(.horizontal)

          ForEach(filteredOptions, id: \.self) { option in
            HStack {
              Text(option)
                .padding(.vertical, 8)
              Spacer()
              Button(role: .destructive) {
                if let idx = options.firstIndex(of: option) {
                  options.remove(at: idx)
                  if selectedOption == option { selectedOption = "Select an Option" }
                }
              } label: {
                Image(systemName: "trash")
                  .foregroundStyle(.red)
              }
            }
            .padding(.horizontal)
            .contentShape(Rectangle())
            .onTapGesture {
              selectedOption = option
              isExpanded = false
            }
          }
        }
        .background()
        .cornerRadius(8)
        .shadow(radius: 5)
      }
    }
    .padding()
  }
}

struct UserView: View {
    @Environment(\.modelContext) private var modelContext
    
    @EnvironmentObject private var currentUser: UserSettings
    
    @State var name: String
    @State var apellidos: String
    @State var fechaNacimiento: Date
    @State var gender: String
    
    @State var medicineAllergy: [Medicine]
    @State private var unwantedMedicineNames: [String] = []
    
    init() {
        self.name = ""
        self.apellidos = ""
        self.fechaNacimiento = Date()
        self.gender = ""
        
        self.medicineAllergy = []
    }
    
    init(selectedUser: User? = nil) {
        if let provided = selectedUser {
            self.name = provided.name
            self.apellidos = provided.apellidos
            self.fechaNacimiento = provided.birthDate
            self.gender = provided.gender
            self.medicineAllergy = provided.publicUnwantedMedicine
        } else {
            self.name = ""
            self.apellidos = ""
            self.fechaNacimiento = Date()
            self.gender = ""
            
            self.medicineAllergy = []
        }
    }
    
    var body: some View {
        ScrollView {
            VStack {
                Text("Nombre(s)")
                    .bold(true)
                TextField("Apellidos", text: $currentUser.user.name)
                
                Text("Apellidos")
                    .bold(true)
                TextField("Apellidos", text: $currentUser.user.apellidos)
                
                Text("Fecha nacimiento")
                    .bold(true)
                DatePicker(
                    "Fecha de nacimiento",
                    selection: $currentUser.user.birthDate,
                    displayedComponents: [.date]
                )
                
                Text("Unwanted Medicines").bold(true)
                SearchableDropdownMenu(options: $unwantedMedicineNames)
                
                Text("Alllergic components").bold(true)
                SearchableDropdownMenu(options: $unwantedMedicineNames)
                
                
                
                Button("Save") {
                    Task {
                        let context = modelContext
                        // Fetch existing medicines by name
                        let fetch = FetchDescriptor<Medicine>()
                        let meds = (try? context.fetch(fetch)) ?? []
                        var byName: [String: Medicine] = [:]
                        for m in meds { byName[m.getName()] = m }
                        
                        // Build final list from names
                        var newList: [Medicine] = []
                        for name in unwantedMedicineNames {
                            if let existing = byName[name] {
                                newList.append(existing)
                            } else {
                                // Create a placeholder medicine with id -1 if missing; adjust as needed for your schema
                                let med = Medicine(id: -1, name: name, descriptionText: "")
                                context.insert(med)
                                newList.append(med)
                            }
                        }
                        currentUser.user.publicUnwantedMedicine = newList
                        try? context.save()
                    }
                }
            }
        }
        .onAppear() {
            if currentUser.user.id != -1 {
                self.name = currentUser.user.name
                self.gender = currentUser.user.gender
                self.apellidos = currentUser.user.apellidos
                
                unwantedMedicineNames = currentUser.user.publicUnwantedMedicine.map { $0.getName() }
            }
        }
    }
}
