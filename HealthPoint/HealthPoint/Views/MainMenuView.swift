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
    
    @Query var users: [User]
    
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
                    
                    welcomeText
                        .padding(.vertical)
                    
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
                    CircleIcon(systemName: "person.fill", paddingSize: 14)
                }
                
                // Dropdown name
                Menu {
                    ForEach(users, id: \.self) { user in
                        Button(action: {
                            currentUser.user = user
                        }) {
                            Text(user.getName())
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(currentUser.user.name)
                            .font(.headline)
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.primary)
                }
                
                Spacer()
                
                CircleIcon(systemName: "gearshape.fill", paddingSize: 14)
            }
        }
    
    var welcomeText: some View {
            Text("""
    Bienvenida \(currentUser.user.getName()),
    selecciona alguno de los
    siguientes modos para
    realizar tu consulta:
    """)
            .multilineTextAlignment(.center)
            .font(.headline)
            .foregroundStyle(.universalAccent)
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
                    title: "Bot de Voz",
                    description: "Consulta a tu Bot de Charla para consultar información de tus medicamentos",
                    selectedOption: $selectedOption
                )
                .padding(.vertical)
                
                ModeCard(
                    title: "Base de Datos",
                    description: "Haz una búsqueda de información farmacéutica en formato tabular sin interacción directa con un Bot",
                    selectedOption: $selectedOption,
                    showSelectors: false
                )
            }
        }
}

struct ModeCard: View {
    var title: String
    var description: String
    @Binding var selectedOption: String
    
    var showSelectors: Bool = true
    
    var body: some View {
        HStack {
            
            VStack(alignment: .leading, spacing: 10) {
                
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.universalAccent)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.black)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil) // or a small number like 3 if you want to cap height
                
                if showSelectors {
                    Picker("", selection: $selectedOption) {
                        Text("Ahorro").tag("Ahorro")
                        Text("Libre").tag("Libre")
                    }
                    .pickerStyle(.segmented)
                    .tint(Color.green)
                }
            }
            
            Spacer()
            
            switch title {
            case "Bot de Charla":// Navigation button
                NavigationLink(destination: chatScreen()) {
                    CircleIcon(systemName: "chevron.right")
                }
                
            case "Bot de Texto":// Navigation button
                NavigationLink(destination: chatScreen()) {
                    CircleIcon(systemName: "chevron.right")
                }
            case "Base de Datos":
                NavigationLink(destination: MedicineExplorer()) {
                    CircleIcon(systemName: "chevron.right")
                }
            default:
                EmptyView()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.foreground).opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color(.universalAccent), lineWidth: 1.5)
                )
        )
    }
}
