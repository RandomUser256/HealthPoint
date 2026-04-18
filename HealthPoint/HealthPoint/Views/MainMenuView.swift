//
//  MainMenuView.swift
//  HealthPoint
//
//  Created by CETYS Universidad  on 14/04/26.
//
import SwiftUI
import SwiftData

struct MainMenuView: View {
    @EnvironmentObject private var currentUser: UserSettings
    
    @Query(sort: \User.name) var users: [User]
    
    @State private var showUserMenu = false
    @State private var selectedOption = "Ahorro"
    
    //@State var selectedScreen: String =
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    
                    header
                        //.padding(.top, 30)
                    
                    welcomeText
                        //.padding(.vertical)
                    
                    Divider()
                        .overlay(Color.gray.opacity(0.4))
                    
                    cardsSection
                    
                    Spacer()
                }
                .padding()
            }
        }
        .foregroundStyle(Color(.background))
    }
}

#Preview {
    MainMenuView()
        .environmentObject(UserSettings()) // Provide a preview instance
        //.modelContainer(for: Item.self, inMemory: true)
}

extension MainMenuView {
    var header: some View {
        HStack {
            // Left button (navigation)
            NavigationLink(destination: UserView(selectedUser: currentUser.user)) {
                CircleIcon(systemName: "person.fill", paddingSize: 20)
            }
            .accessibilityLabel("Abrir perfil")
            .accessibilityHint("Muestra la información del usuario actual")
            
            // Dropdown name
            Menu {
                Button(action: {
                    currentUser.user = User()
                }) {
                    Text("Nuevo Usuario")
                        .font(.system(size: 20))
                }
                .accessibilityLabel("Crear nuevo usuario")
                
                ForEach(users, id: \.self) { user in
                    Button(action: {
                        currentUser.user = user
                    }) {
                        Text(user.getName())
                            .font(.system(size: 20))
                    }
                    .accessibilityLabel("Seleccionar usuario \(user.getName())")
                }
            } label: {
                HStack(spacing: 4) {
                    Text(currentUser.user.name)
                        .font(.system(size: 20, weight: .semibold))
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(.primary)
                .contentShape(Rectangle())
            }
            .accessibilityLabel("Seleccionar usuario")
            .accessibilityValue(currentUser.user.name)
            .accessibilityHint("Abre la lista de usuarios disponibles")
            
            Spacer()
            
            //CircleIcon(systemName: "gearshape.fill", paddingSize: 20)
        }
    }
    
    /// Displays the personalized welcome message and preserves its full multiline layout.
    var welcomeText: some View {
            Text("""
    Bienvenida \(currentUser.user.getName()),
    selecciona alguno de los
    siguientes modos para
    realizar tu consulta:
    """)
        .multilineTextAlignment(.center)
        .font(.system(size: 22, weight: .semibold, design: .default))
        .lineSpacing(6)
        .minimumScaleFactor(0.9)
        .foregroundStyle(.universalAccent)
        .padding(.horizontal)
        // Lets the text wrap within the available width while growing vertically
        // so no lines are compressed into a smaller height.
        .fixedSize(horizontal: false, vertical: true)
    }
    
    var cardsSection: some View {
            VStack(spacing: 16) {
                
                ModeCard(
                    title: "Bot de Charla",
                    description: "Consulta a tu Bot de Charla para recibir información de tus medicamentos",
                    selectedOption: $selectedOption
                )
                .padding(.top)
                
                ModeCard(
                    title: "Base de Datos",
                    description: "Haz una búsqueda de información farmacéutica en formato tabular sin interacción directa con un Bot",
                    selectedOption: $selectedOption,
                    showSelectors: false
                )
                .padding(.top, 30)
            }
        }
}

struct ModeCard: View {
    var title: String
    var description: String
    @Binding var selectedOption: String
    
    var showSelectors: Bool = true
    
    @State private var dummyTapBlocker: Bool = false
    @State private var go: Bool = false

    private var accessibilityLabelText: String {
        "\(title). \(description)"
    }

    private var accessibilityHintText: String {
        switch title {
        case "Base de Datos":
            return "Abre el explorador de medicamentos"
        default:
            return "Abre el chat farmacéutico"
        }
    }

    private func triggerNavigation() {
        switch title {
        case "Bot de Charla", "Bot de Texto", "Base de Datos":
            go = true
        default:
            break
        }
    }
    
    var body: some View {
        HStack {
            
            VStack(alignment: .leading, spacing: 10) {
                
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.universalAccent)
                
                Text(description)
                    .font(.system(size: 17))
                    .foregroundColor(.black)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)
                /*
                if showSelectors {
                    Picker("", selection: $selectedOption) {
                        Text("Amaro").tag("Amaro")
                        Text("Hilda").tag("Hilda")
                    }
                    .pickerStyle(.segmented)
                    .tint(Color.green)
                    .frame(maxWidth: 350)
                    .allowsHitTesting(true)
                    .highPriorityGesture(TapGesture().onEnded { _ in })
                }
                 */
            }
            
            Spacer()
            
            switch title {
            case "Bot de Charla":
                ZStack {
                    NavigationLink(destination: chatScreen(), isActive: $go) { EmptyView() }
                        .hidden()
                    CircleIcon(systemName: "chevron.right")
                }
                
            case "Bot de Texto":
                ZStack {
                    NavigationLink(destination: chatScreen(), isActive: $go) { EmptyView() }
                        .hidden()
                    CircleIcon(systemName: "chevron.right")
                }
                
            case "Base de Datos":
                ZStack {
                    NavigationLink(destination: MedicineExplorer(), isActive: $go) { EmptyView() }
                        .hidden()
                    CircleIcon(systemName: "chevron.right")
                }
            default:
                EmptyView()
            }
        }
        .padding()
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.foreground).opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color(.universalAccent), lineWidth: 1.5)
                )
        )
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            triggerNavigation()
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint(accessibilityHintText)
        .accessibilityAction {
            triggerNavigation()
        }
    }
}
