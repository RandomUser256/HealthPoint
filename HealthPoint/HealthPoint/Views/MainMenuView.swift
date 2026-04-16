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
        /*
        NavigationStack {
            VStack {
                Spacer()
                Text("HealthPoint")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 8)
                Text("Main Menu")
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                NavigationLink (destination: chatScreen() ,label: {
                    Label("Open chatbot", systemImage: "message.fill")
                        .font(.title2)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                })
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal)
                
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
                
                NavigationLink (destination: UserView() ,label: {
                    Label("Crear nuevo usuario", systemImage: "pills.fill")
                        .font(.headline)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                })
                .buttonStyle(.bordered)
                .padding(.horizontal)
                .padding(.bottom, 24)
                
                NavigationLink (destination: UserView(selectedUser: currentUser.user) ,label: {
                    Label("Open User settings", systemImage: "pills.fill")
                        .font(.headline)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                })
                .buttonStyle(.bordered)
                .padding(.horizontal)
                .padding(.bottom, 24)
                
                Spacer()
                
                NavigationLink (destination: MedicineExplorer(), label: {
                    Label("Open Medicines List", systemImage: "pills.fill")
                        .font(.headline)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                })
                .buttonStyle(.bordered)
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .tint(.green)
         */
        NavigationStack {
                    ZStack {
                        Color(.systemGroupedBackground)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 24) {
                            
                            header
                            
                            welcomeText
                            
                            Divider()
                                .overlay(Color.gray.opacity(0.4))
                            
                            cardsSection
                            
                            Spacer()
                        }
                        .padding()
                    }
                }
    }
}

#Preview {
    MainMenuView()
}

extension MainMenuView {
    var header: some View {
            HStack {
                // Left button (navigation)
                NavigationLink(destination: UserView(selectedUser: currentUser.user)) {
                    CircleIcon(systemName: "circle.fill")
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
                
                CircleIcon(systemName: "gearshape")
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
            .font(.subheadline)
        }
    
    var cardsSection: some View {
            VStack(spacing: 16) {
                
                ModeCard(
                    title: "Bot de Charla",
                    description: "Consulta a tu Bot de Charla para recibir información de tus medicamentos",
                    selectedOption: $selectedOption
                )
                
                ModeCard(
                    title: "Bot de Voz",
                    description: "Consulta a tu Bot de Charla para consultar información de tus medicamentos",
                    selectedOption: $selectedOption
                )
                
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
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
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
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.green.opacity(0.4), lineWidth: 1.5)
                )
        )
    }
}
