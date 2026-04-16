//
//  UserView.swift
//  HealthPoint
//
//  Created by CETYS Universidad  on 14/04/26.
//
import SwiftUI
import SwiftData

///WARNINGS
///- In dropdown view, add and delete options are not linked or fact checked with the database, fix or disable function

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
    
    @Bindable var currentUser: User
    
    //@State private var localUser: User?
    
    @State private var newUser: Bool = false
    @State private var saveChanges: Bool = false
    
    @State var name: String
    @State var apellidos: String
    @State var fechaNacimiento: Date
    @State var gender: String
    
    @State var medicineAllergy: [Medicine]
    @State var ingredientAllergy: [Ingredient]
    
    @State private var unwantedMedicineNames: [String] = []
    @State private var unwantedAllergy : [String] = []
    
    @State private var userNames: [String] = []
    
    init(selectedUser: User) {
        
            _currentUser = Bindable(selectedUser)
            
            self.name = selectedUser.name
            self.apellidos = selectedUser.apellidos
            self.fechaNacimiento = selectedUser.birthDate
            self.gender = selectedUser.gender
            self.medicineAllergy = selectedUser.publicUnwantedMedicine
            self.ingredientAllergy = selectedUser.publicIngredientAllergies
        /*} else {
            self.currentUser = User()
            
            self.newUser = true
            
            self.name = ""
            self.apellidos = ""
            self.fechaNacimiento = Date()
            self.gender = ""
            
            self.medicineAllergy = []
            self.ingredientAllergy = []
        }
         */
    }
    
    func userList() {
        let context = modelContext
        let fetch = FetchDescriptor<User>()
        let users = (try? context.fetch(fetch)) ?? []
        let names = users.map { $0.name }
        self.userNames = names
    }
    
    var body: some View {
        ScrollView {
            VStack {
                Text("Users")
                    .bold(true)
                SearchableDropdownMenu(options: $userNames)
                
                Text("Nombre(s)")
                    .bold(true)
                TextField("Apellidos", text: $currentUser.name)
                
                Text("Apellidos")
                    .bold(true)
                TextField("Apellidos", text: $currentUser.apellidos)
                
                Text("Fecha nacimiento")
                    .bold(true)
                DatePicker(
                    "Fecha de nacimiento",
                    selection: $currentUser.birthDate,
                    displayedComponents: [.date]
                )
                
                Text("Unwanted Medicines").bold(true)
                SearchableDropdownMenu(options: $unwantedMedicineNames)
                
                Text("Alllergic components").bold(true)
                SearchableDropdownMenu(options: $unwantedMedicineNames)
                
                
                
                Button("Save") {
                    Task {
                        self.saveChanges = true
                        //let context = modelContext
                        // Fetch existing medicines by name
                        /*
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
                         */
                        //try? context.save()
                    }
                }
            }
            .onAppear() {
                userList()
            }
        }
        .onAppear() {
            /*
            if currentUser.id != -1 {
                self.name = currentUser.user.name
                self.gender = currentUser.user.gender
                self.apellidos = currentUser.user.apellidos
                
                unwantedMedicineNames = currentUser.user.publicUnwantedMedicine.map { $0.getName() }
                unwantedAllergy = currentUser.user.publicIngredientAllergies.map { $0.getName() }
            }
             */
        }
        .onDisappear() {
            
            if saveChanges {
                /*
                currentUser.user.name = self.name
                currentUser.user.apellidos = self.apellidos
                currentUser.user.birthDate = self.fechaNacimiento
                currentUser.user.gender = self.gender
                
                currentUser.user.publicUnwantedMedicine = self.medicineAllergy
                currentUser.user.publicIngredientAllergies = self.ingredientAllergy
                 */
                
                currentUser.name = self.name
                currentUser.apellidos = self.apellidos
                currentUser.birthDate = self.fechaNacimiento
                currentUser.gender = self.gender
                
                currentUser.publicUnwantedMedicine = self.medicineAllergy
                currentUser.publicIngredientAllergies = self.ingredientAllergy
                
                modelContext.insert(currentUser)

            }
            
            do {
                try modelContext.save()
            } catch {
                print("Error saving user information: \(error)")
            }
        }
    }
}
