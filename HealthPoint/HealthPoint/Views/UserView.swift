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
            /*
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
             */

          ForEach(filteredOptions, id: \.self) { option in
            HStack {
              Text(option)
                .padding(.vertical, 8)
              Spacer()
                /*
              Button(role: .destructive) {
                if let idx = options.firstIndex(of: option) {
                  options.remove(at: idx)
                  if selectedOption == option { selectedOption = "Select an Option" }
                }
              } label: {
                Image(systemName: "trash")
                  .foregroundStyle(.red)
              }
                 */
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

struct DropdownMenuDisclosureGroup: View {
  @State private var isExpanded: Bool = false
  @State private var message: String = "Alergias"
    
    @EnvironmentObject private var currentUser: UserSettings

  var body: some View {
    DisclosureGroup(message, isExpanded: $isExpanded) {
      VStack {
          ForEach(currentUser.user.publicIngredientAllergies, id: \.self) { ing in
              Text(ing.getName())
            .padding()
            .onTapGesture {
              
              isExpanded = false
            }
        }
      }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .cornerRadius(8)
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
        
        //let provided = currentUser.user
        
        //_selectedUser = Bindable(currentUser.user)
        
        
        
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
        /*
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
          
          */
         
         Text("Alergias").bold(true)
         SearchableDropdownMenu(options: $currentUser.user.publicIngredientAllergies)
         
         
         
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
         }*/
        /*
         ScrollView {
         VStack(alignment: .leading, spacing: 20) {
         
         // Header
         HStack {
         Button(action: {}) {
         Image(systemName: "square.grid.2x2")
         .padding()
         .background(Color.green.opacity(0.2))
         .clipShape(Circle())
         }
         
         Spacer()
         
         Button(action: {}) {
         Image(systemName: "gearshape")
         .padding()
         .background(Color.green.opacity(0.2))
         .clipShape(Circle())
         }
         }
         
         Text("Perfil")
         .font(.largeTitle)
         .bold()
         
         // Inputs
         Group {
         CustomTextField(title: "Nombre(s)", text: $selectedUser.name)
         CustomTextField(title: "Apellido Paterno", text: $selectedUser.apellidos)
         //CustomTextField(title: "Apellido Materno", text: $apellidoMaterno)
         }
         
         // Fecha de nacimiento
         
         VStack(alignment: .leading, spacing: 10) {
         Text("Fecha de nacimiento")
         .font(.headline)
         
         HStack {
         Picker("Día", selection: $selectingUser.birthdate) {
         ForEach(dias, id: \.self) { Text("\($0)") }
         }
         .pickerStyle(MenuPickerStyle())
         
         Picker("Mes", selection: $mes) {
         ForEach(meses, id: \.self) { Text("\($0)") }
         }
         .pickerStyle(MenuPickerStyle())
         
         Picker("Año", selection: $anio) {
         ForEach(anios, id: \.self) { Text("\($0)") }
         }
         .pickerStyle(MenuPickerStyle())
         }
         
         }
         VStack {
         Text("Fecha de nacimiento")
         .font(.headline)
         
         DatePicker(
         "",
         selection: $selectedUser.birthDate,
         displayedComponents: [.date]
         )
         .datePickerStyle(.wheel)
         }
         
         // Género
         VStack(alignment: .leading, spacing: 10) {
         Text("Género biológico")
         .font(.headline)
         
         Picker("", selection: $selectedUser.gender) {
         Text("Masculino").tag("M")
         Text("Femenino").tag("F")
         }
         .pickerStyle(SegmentedPickerStyle())
         }
         
         // Otras configuraciones
         VStack(alignment: .leading, spacing: 10) {
         Text("Otras configuraciones...")
         .font(.headline)
         
         NavigationRow(title: "Diagnósticos médicos")
         NavigationRow(title: "Alergias")
         NavigationRow(title: "Configuración de Bots")
         }
         
         }
         .padding()
         }
         .background(Color(.systemGray6))
         */
        
        ScrollView {
            VStack(spacing: 24) {
                
                header
                
                title
                
                datosPersonalesCard
                
                fechaNacimientoCard
                
                generoCard
                
                configuracionesCard
                
                HStack {
                    saveButton
                    
                    deleteButton
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
         
}

#Preview {
    UserView()
}

extension UserView {
    var header: some View {
            HStack {
                CircleIcon(systemName: "square.grid.2x2")
                Spacer()
                CircleIcon(systemName: "gearshape")
            }
        }
    
    var title: some View {
            Text("Perfil")
                .font(.largeTitle)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    
    var datosPersonalesCard: some View {
            //CardView {
                VStack(spacing: 16) {
                    CustomTextField(title: "Nombre(s)", text: $selectedUser.name)
                    CustomTextField(title: "Apellidos", text: $selectedUser.apellidos)
                    //CustomTextField(title: "Apellido Materno", text: $apellidoMaterno)
                }
            //}
        }
    
    var fechaNacimientoCard: some View {
            //CardView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Fecha de nacimiento")
                        .font(.headline)
                    
                    DatePicker(
                        "",
                        selection: $selectedUser.birthDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                }
            //}
        }
    
    var generoCard: some View {
            //CardView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Género biológico")
                        .font(.headline)
                    
                    Picker("", selection: $selectedUser.gender) {
                        Text("Masculino").tag("M")
                        Text("Femenino").tag("F")
                    }
                    .pickerStyle(.segmented)
                    .tint(Color.green)
                }
           // }
        }
    
    var saveButton: some View {
        Button("Save") {
            Task {
                do {
                    // Insert only if new
                    if self.newUser {
                        modelContext.insert(selectedUser)
                    }
                    try modelContext.save()
                } catch {
                    print("Error saving user: \(error)")
                }
                
                dismiss()
            }
        }
        .foregroundColor(.green)
        .padding(30)
        .background(Color.green.opacity(0.15))
        .clipShape(Circle())
    }
    
    var deleteButton: some View {
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
        .foregroundColor(.green)
        .padding(30)
        .background(Color.green.opacity(0.15))
        .clipShape(Circle())
        
    }
    
    var configuracionesCard: some View {
            VStack(alignment: .leading, spacing: 12) {
                
                Text("Otras configuraciones...")
                    .font(.headline)
                /*
                ExpandableCard(
                    title: "Diagnósticos médicos",
                    isExpanded: $showDiagnosticos
                ) {
                    Text("Aquí puedes agregar diagnósticos")
                }
                 
                 
                 ExpandableCard(
                     title: "Configuración de Bots",
                     isExpanded: $showBots
                 ) {
                     Text("Preferencias del chatbot médico")
                 }
                 */
                
                ExpandableCard(
                    title: "Alergias",
                    isExpanded: $selectingUser,
                ) {
                    Group {
                        List {
                            ForEach($selectedUser.publicIngredientAllergies, id: \.self) { ing in
                                HStack {
                                    TextField("", text: ing.normalizedName)
                                        .font(.subheadline)
                                    /*
                                     Button (action: {
                                     $selectedUser.publicIngredientAllergies
                                     }) {
                                     Image(systemName: "minus.circle.fill")
                                     }
                                     */
                                }
                            }
                        }
                    }
                }
                
            }
        }
}

struct CardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack {
            content
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

struct ExpandableCard<Content: View>: View {
    var title: String
    @Binding var isExpanded: Bool
    var content: Content
    
    init(title: String, isExpanded: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self.title = title
        self._isExpanded = isExpanded
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(title)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .foregroundColor(.gray)
                }
                .padding()
            }
            
            if isExpanded {
                Divider()
                content
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }
}

struct CircleIcon: View {
    var systemName: String
    
    var body: some View {
        Image(systemName: systemName)
            .foregroundColor(.green)
            .padding()
            .background(Color.green.opacity(0.15))
            .clipShape(Circle())
    }
}



struct CustomTextField: View {
    var title: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.headline)
            
            TextField("", text: $text)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3))
                )
        }
    }
}

struct NavigationRow: View {
    var title: String
    
    var body: some View {
        Button(action: {
            // Navigate later
        }) {
            HStack {
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }
}
