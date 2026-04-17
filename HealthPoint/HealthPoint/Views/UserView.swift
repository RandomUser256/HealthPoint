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
      .accessibilityLabel("Seleccionar opción")
      .accessibilityValue(selectedOption)
      .accessibilityHint("Abre la lista de opciones disponibles")

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

    private var allergyItems: [Ingredient] {
        selectedUser.publicIngredientAllergies
            .sorted { $0.getName().localizedCaseInsensitiveCompare($1.getName()) == .orderedAscending }
    }

    private func nextUserID() -> Int {
        (userList.map(\.id).max() ?? 0) + 1
    }
    
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
                    
                        .padding(.trailing, 60)
                    
                    deleteButton
                }
            }
            .padding()
        }
        .background(Color(.background).opacity(0.4))
    }

    private func removeIngredientAllergy(_ ingredient: Ingredient) {
        selectedUser.publicIngredientAllergies.removeAll { $0.id == ingredient.id }
        currentUser.user.publicIngredientAllergies.removeAll { $0.id == ingredient.id }
    }

    private func persistUser() {
        do {
            if newUser {
                selectedUser.id = nextUserID()
                modelContext.insert(selectedUser)
            }

            try modelContext.save()
            currentUser.user = selectedUser
            dismiss()
        } catch {
            print("Error saving user: \(error)")
        }
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
                .foregroundStyle(.universalAccent)
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
                        .foregroundStyle(.universalAccent)
                    
                    DatePicker(
                        "",
                        selection: $selectedUser.birthDate,
                        in: ...Date.now,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                }
            //}
        }
    
    var generoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Género biológico")
                .font(.headline)
                .foregroundStyle(.universalAccent)
            
            Picker("Gender", selection: $selectedUser.gender) {
                Text("Masculino")
                    .foregroundStyle(selectedUser.gender == "M" ? .white : .primary)
                    .tag("M")
                
                Text("Femenino")
                    .foregroundStyle(selectedUser.gender == "F" ? .white : .primary)
                    .tag("F")
            }
            .pickerStyle(.segmented)
            .tint(Color(.universalAccent)) // accent color of the selected segment capsule
            .foregroundStyle(.universalAccent)
        }
    }
    
    var saveButton: some View {
        Button(action: {
            persistUser()
        }) {
            VStack {
                Image(systemName: "checkmark")
                    .foregroundColor(.green)
                    .padding(25)
                    .background(.universalAccent)
                    .clipShape(Circle())
                Text("Save")
                    .font(.subheadline)
                    .foregroundStyle(.universalAccent)
            }
        }
        .accessibilityLabel("Guardar perfil")
        .accessibilityHint("Guarda los cambios del usuario actual")
    }
    
    var deleteButton: some View {
        Button(action: {
            let replacementUser = userList.first { $0.id != selectedUser.id }

            modelContext.delete(selectedUser)

            do {
                try modelContext.save()

                if currentUser.user.id == selectedUser.id {
                    currentUser.user = replacementUser ?? User()
                }

                dismiss()
            } catch {
                print("Error saving user: \(error)")
            }
        }) {
            VStack {
                Image(systemName: "trash.fill")
                    .foregroundColor(.green)
                    .padding(25)
                    .background(.universalAccent)
                    .clipShape(Circle())
                Text("Delete")
                    .font(.subheadline)
                    .foregroundStyle(.universalAccent)
            }
        }
        .accessibilityLabel("Eliminar perfil")
        .accessibilityHint("Elimina este usuario y cierra la pantalla")
        
    }
    
    var configuracionesCard: some View {
            VStack(alignment: .leading, spacing: 12) {
                
                Text("Otras configuraciones...")
                    .font(.headline)
                    .foregroundStyle(.universalAccent)
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
                    VStack(alignment: .leading, spacing: 12) {
                        if allergyItems.isEmpty {
                            Text("No hay ingredientes vinculados.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(allergyItems, id: \.id) { ingredient in
                                HStack(spacing: 12) {
                                    Text(ingredient.getName())
                                        .font(.subheadline)
                                        .foregroundStyle(.black)

                                    Spacer()

                                    Button {
                                        removeIngredientAllergy(ingredient)
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundStyle(.green)
                                            .padding(12)
                                            .background(.universalAccent)
                                            .clipShape(Circle())
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Eliminar alergia a \(ingredient.getName())")
                                    .accessibilityHint("Quita este ingrediente de la lista de alergias")
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color(.background).opacity(0.5))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(Color(.universalAccent).opacity(0.8))
                                        )
                                )
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
            .buttonStyle(.plain)
            .accessibilityLabel("\(title), \(isExpanded ? "expandido" : "contraído")")
            .accessibilityHint("Activa para \(isExpanded ? "ocultar" : "mostrar") el contenido")
            
            if isExpanded {
                Divider()
                content
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .contentShape(RoundedRectangle(cornerRadius: 14.0))
    }
}

struct CircleIcon: View {
    var systemName: String
    var paddingSize: Double = 20
    
    var body: some View {
        Image(systemName: systemName)
            .foregroundColor(.green)
            .padding(paddingSize)
            .background(.universalAccent)
            .clipShape(Circle())
            .accessibilityHidden(true)
    }
}



struct CustomTextField: View {
    var title: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.universalAccent)
            
            TextField("", text: $text)
                .padding()
                .background(Color(.background).opacity(0.5))
                .foregroundStyle(.black)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(.universalAccent).opacity(0.8))
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
        .accessibilityLabel(title)
        .accessibilityHint("Abre esta sección")
    }
}
