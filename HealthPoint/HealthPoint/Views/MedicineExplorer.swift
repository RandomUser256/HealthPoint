import SwiftUI
import SwiftData
import Foundation
internal import Combine


struct MedicineExplorer: View {
    @Environment(\.modelContext) private var modelContext
    
    @EnvironmentObject private var currentUser: UserSettings
    
    @StateObject private var model = MedicineExplorerViewModel()
    
    @State private var allMedicines: Int = 0

    var body: some View {
        
            Group {
                //When no registered medicines
                if model.sectioned.isEmpty {
                    ContentUnavailableView("No results", systemImage: "pills", description: Text("Try adjusting your search or filters."))
                } else {
                    List {
                        //Cycles medicine array's contained in each "sectioned" entry
                        ForEach(model.sectioned, id: \.key) { section in
                            //Creates list UI section
                            Section(section.key) {
                                ForEach(section.items) { item in
                                    //Navigation link that displays new elements when preseed
                                    NavigationLink(destination: MedicineDetailView(medicine: item)) {
                                        //Displayed elements in list rows
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.getName())
                                                .font(.headline)
                                            Text(item.getDescriptionText())
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(2)
                                        }
                                        //Calls load more task if end of list is reached
                                        .task {
                                            model.loadMoreIfNeeded(current: item)
                                        }
                                    }
                                }
                            }
                        }
                        //Shows bottom progress bar for loading new elements if applicable
                        if model.displayed.count < allMedicines {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .onAppear { model.increasePage() }
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Explore Medicines")
            .searchable(text: $model.query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search medicines")
            .toolbar {
                //Holds filtering actions for list view
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        //Dropdown menu for filters
                        Picker("Sort order", selection: $model.sortAscending) {
                            Text("Name A–Z").tag(true)
                            Text("Name Z–A").tag(false)
                        }
                        .pickerStyle(.inline)
                        //Toggles "filterByUserPreferences" variable
                        Toggle(isOn: $model.filterByUserPreferences) {
                            Label("Respect user allergies & unwanted", systemImage: "line.3.horizontal.decrease.circle")
                        }
                    } label: {
                        Label("Filters", systemImage: "arrow.up.arrow.down.circle")
                    }
                }
            }
            //Actions when view is rendered and/or re-rendered
            .onAppear {
                model.setContext(modelContext)
                
                //Updates current user of MedicineExplorerViewModel, which is in charge of fetching listed items
                model.currentUser = currentUser
                
                //Load items
                model.loadFromStore()
                
                //Fetches total count of registered medicine
                let descriptor = FetchDescriptor<Medicine>()
                allMedicines = (try? modelContext.fetchCount(descriptor)) ?? 0
            }
            .onChange(of: allMedicines) { _, _ in
                //Reload items if total amount of medicine is changed
                model.loadFromStore()
            }
            //For each list item, sets the destination when clicked
            .navigationDestination(for: Medicine.self) { medicine in
                MedicineDetailView(medicine: medicine)
            }
        }
    
}


#Preview {
    // Preview without a user
    MedicineExplorer()
}
