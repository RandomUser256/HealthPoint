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
/*
struct UserPickerView: View {
    @EnvironmentObject var currentUser: UserSettings

    @Bindable var users: [User]
    
    @Query
    
    init(users: [User]? = nil) {
        if let provided = users {
            _users = Bindable(provided)
        } else {
            _users = Bindable([])
        }
    }

    var body: some View {
        List {
            ForEach(users, id: \.id) { usr in
                HStack {
                    Text(usr.name)
                        .padding(.horizontal, 10)
                    if currentUser.user.id == usr.id {
                        Image(systemName: "circle")
                    } else {
                        Image(systemName: "circle.fill")
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    currentUser.user = usr
                }
            }
        }
        .navigationTitle("Choose User")
    }
}
*/
struct UserView: View {
    @Environment(\.modelContext) private var modelContext
    
    //@Bindable var currentUser: User
    
    @EnvironmentObject private var currentUser: UserSettings

    @Bindable var selectedUser: User
    
    @Query var userList: [User]
    
    //@Query(sort: \User.name) var users: [User] // SwiftData query for all users
    
    //@State private var localUser: User?
    
    @State private var newUser: Bool
    @State private var saveChanges: Bool = false
    @State private var deleteUser: Bool = false
    
  /*
    @State var name: String
    @State var apellidos: String
    @State var fechaNacimiento: Date
    @State var gender: String
    
    @State var medicineAllergy: [Medicine]
    @State var ingredientAllergy: [Ingredient]
    
    @State private var unwantedMedicineNames: [String] = []
    @State private var unwantedAllergy : [String] = []
   */
    
    @State private var userNames: [String] = []
    
    @State private var selectingUser: Bool = false
    
    //@State private var usrList: [User]
    
    @Environment(\.dismiss) var dismiss
    
    init(selectedUser: User? = nil) {
        /*
        self._name = State(initialValue: selectedUser.name)
        self._apellidos = State(initialValue: selectedUser.apellidos)
        self._fechaNacimiento = State(initialValue: selectedUser.birthDate)
        self._gender = State(initialValue: selectedUser.gender)
        self._medicineAllergy = State(initialValue: selectedUser.publicUnwantedMedicine)
        self._ingredientAllergy = State(initialValue: selectedUser.publicIngredientAllergies)
        self._usrList = State(initialValue: [])
         */
        
        if let provided = selectedUser {
            _selectedUser = Bindable(provided)
            self.newUser = false
        } else {
            let newUser = User()
            _selectedUser = Bindable(newUser)
            self.newUser = true
        }
    }
    
    /*func userList() {
        let context = modelContext
        let fetch = FetchDescriptor<User>()
        self.usrList = (try? context.fetch(fetch)) ?? []
        //let names = users.map { $0.name }
        //self.userNames = names
    }*/
    
    var body: some View {
        ScrollView {
            VStack {
                Button(action: {
                    selectingUser.toggle()
                }) {
                    Text("Users")
                        .bold(true)
                }
                
                Text("Nombre(s)")
                    .bold(true)
                TextField("Nombre(s)", text: $selectedUser.name)
                
                Text("Apellidos")
                    .bold(true)
                TextField("Apellidos", text: $selectedUser.apellidos)
                
                Text("Fecha nacimiento")
                    .bold(true)
                DatePicker(
                    "Fecha de nacimiento",
                    selection: $selectedUser.birthDate,
                    displayedComponents: [.date]
                )
                /*
                Text("Unwanted Medicines").bold(true)
                SearchableDropdownMenu(options: $currentUser.user.publicUnwantedMedicine)
                
                Text("Alllergic components").bold(true)
                SearchableDropdownMenu(options: $currentUser.user.unwantedAllergy)
                */
                
                
                Button("Save") {
                    Task {
                        do {
                            
                            // Insert only if new
                            if self.newUser {
                                modelContext.insert(selectedUser)
                            }
                            /*
                            // Apply edits
                            currentUser.user.name = name
                            currentUser.user.apellidos = apellidos
                            currentUser.user.birthDate = fechaNacimiento
                            currentUser.user.gender = gender
                            currentUser.user.publicUnwantedMedicine = medicineAllergy
                            currentUser.user.publicIngredientAllergies = ingredientAllergy
                            */
                            try modelContext.save()
                        } catch {
                            print("Error saving user: \(error)")
                        }
                        
                        dismiss()
                    }
                }
                
                Button("Delete") {
                    Task {
                        modelContext.delete(selectedUser)
                        
                        do {
                            try modelContext.save()
                        } catch {
                            print("Error saving user: \(error)")
                        }
                        
                        dismiss()
                    }
                }
                /*
                if selectingUser {
                    List {
                        ForEach(userList, id: \.id) { usr in
                            HStack {
                                Text(usr.name)
                                    .padding(.horizontal, 10)
                                if currentUser.user.id == usr.id {
                                    Image(systemName: "circle")
                                } else {
                                    Image(systemName: "circle.fill")
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                currentUser.user = usr
                            }
                        }
                    }
                } else {
                    
                }
                 */
            }
                
            
        }
        .onAppear() {
            if newUser {
                modelContext.insert(currentUser.user)
                // If the currentUser.user is not yet managed, insert it now
                /*
                 if modelContext.model(for: currentUser.user) == nil {
                    modelContext.insert(currentUser.user)
                }
                 */
            }
        }
        .onDisappear() {
            /*
            if saveChanges {
                currentUser.user.name = self.name
                currentUser.user.apellidos = self.apellidos
                currentUser.user.birthDate = self.fechaNacimiento
                currentUser.user.gender = self.gender
                currentUser.user.publicUnwantedMedicine = self.medicineAllergy
                currentUser.user.publicIngredientAllergies = self.ingredientAllergy
                modelContext.insert(currentUser.user)
            }
            else if deleteUser {
                modelContext.delete(currentUser.user)
            }
            
            do {
                if saveChanges {
                    try modelContext.save()
                }
            } catch {
                print("Error saving/deleteing user information: \(error)")
            }
             */
        }
    }
}
