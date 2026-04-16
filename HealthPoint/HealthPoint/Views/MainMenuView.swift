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
    
    @Query var userList: [User]
    
    //@State var selectedScreen: String = 
    
    var body: some View {
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
    }
}
