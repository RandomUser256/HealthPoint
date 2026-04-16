import SwiftUI
import SwiftData
import Foundation
internal import Combine


struct MedicineExplorer: View {
    @Environment(\.modelContext) private var modelContext
    
    @EnvironmentObject private var currentUser: UserSettings
    
    @StateObject private var model = MedicineExplorerViewModel()
    
    @State private var allMedicines: Int = 0
    
    @State private var expandedMedicineID: Int? = nil

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            Group {
                // When no registered medicines
                if model.sectioned.isEmpty {
                    ContentUnavailableView(
                        "No results",
                        systemImage: "pills",
                        description: Text("Try adjusting your search or filters.")
                    )
                } else {
                    List {
                        ForEach(model.sectioned, id: \.key) { section in
                            Section {
                                ForEach(section.items) { item in
                                    MedicineExplorerCard(
                                        item: item,
                                        isExpanded: expandedMedicineID == item.id,
                                        currentUser: currentUser,
                                        toggleExpansion: {
                                            withAnimation(.easeInOut) {
                                                if expandedMedicineID == item.id {
                                                    expandedMedicineID = nil
                                                } else {
                                                    expandedMedicineID = item.id
                                                }
                                            }
                                        }
                                    )
                                    .task {
                                        model.loadMoreIfNeeded(current: item)
                                    }
                                    .padding(.vertical, 6)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                }
                            }
                            header: {
                                Text(section.key)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.universalAccent)
                                    .padding(.leading, 4)
                                    .padding(.top, 12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .textCase(nil)
                            }
                        }
                        
                        
                        // Pagination loader
                        if model.displayed.count < allMedicines {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .tint(.universalAccent)
                                    .onAppear { model.increasePage() }
                                Spacer()
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                }
            }
            .navigationTitle("Explore Medicines")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $model.query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search medicines"
            )
            
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Picker("Sort order", selection: $model.sortAscending) {
                            Text("Name A–Z").tag(true)
                            Text("Name Z–A").tag(false)
                        }
                        .pickerStyle(.inline)

                        Toggle(isOn: $model.filterByUserPreferences) {
                            Label(
                                "Respect user allergies & unwanted",
                                systemImage: "line.3.horizontal.decrease.circle"
                            )
                        }
                        
                    } label: {
                        CircleIcon(systemName: "arrow.up.arrow.down", paddingSize: 14)
                    }
                }
            }
            .onAppear {
                model.setContext(modelContext)
                model.currentUser = currentUser
                model.loadFromStore()

                let descriptor = FetchDescriptor<Medicine>()
                allMedicines = (try? modelContext.fetchCount(descriptor)) ?? 0
            }
            .onChange(of: allMedicines) { _, _ in
                model.loadFromStore()
            }
            .onChange(of: model.displayed.map(\.id)) { _, ids in
                if let expandedMedicineID, !ids.contains(expandedMedicineID) {
                    self.expandedMedicineID = nil
                }
            }
            .navigationDestination(for: Medicine.self) { medicine in
                MedicineDetailView(medicine: medicine)
            }
        }
    }
}


#Preview("Medicine Explorer") {
    MedicineExplorer()
        .environmentObject(UserSettings())
        .modelContainer(for: Item.self, inMemory: true)
}

private struct MedicineExplorerCard: View {
    let item: Medicine
    let isExpanded: Bool
    let currentUser: UserSettings
    let toggleExpansion: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: toggleExpansion) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.getName())
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.universalAccent)

                        Text(item.getDescriptionText())
                            .font(.system(size: 17))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 18, weight: .semibold))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .foregroundStyle(.universalAccent)
                }
                .contentShape(RoundedRectangle(cornerRadius: 18))
                .padding(18)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()
                    .padding(.horizontal)

                MedicineDetailView(medicine: item)
                    .environmentObject(currentUser)
                    .frame(maxWidth: .infinity)
                    .background(Color.clear)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(2)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(Color(.foreground).opacity(0.4))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color(.universalAccent), lineWidth: 1.5)
            )
    }
}
#Preview {
    MedicineExplorer()
        .environmentObject(UserSettings())
}

struct MedicineDetailView: View {
    let medicine: Medicine

    @EnvironmentObject private var currentUser: UserSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text(medicine.getName())
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.universalAccent)

                Text(medicine.getDescriptionText())
                    .font(.system(size: 18))
                    .foregroundStyle(.primary, .black)
                    .lineSpacing(5)
            }

            if !medicine.ingredients.isEmpty {
                detailSection(title: "Ingredientes") {
                    ForEach(medicine.ingredients, id: \.self) { ing in
                        HStack(spacing: 14) {
                            Text(ing.getName())
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.black)

                            Spacer()

                            Button(action: {
                                currentUser.user.publicIngredientAllergies.append(ing)
                            }) {
                                Image(systemName:
                                    currentUser.user.publicUnwantedMedicine.contains { $0.id == ing.id }
                                    ? "checkmark.circle.fill"
                                    : "plus.circle.fill"
                                )
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(.green)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.systemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color(.universalAccent).opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
            }

            if !medicine.adverseEffects.isEmpty {
                detailSection(title: "Efectos secundarios") {
                    ForEach(medicine.adverseEffects, id: \.self) { ing in
                        Text(ing.getName())
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(.systemBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color(.universalAccent).opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                }
            }
        }
        .padding(18)
    }

    private func detailSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(.universalAccent)

            content()
        }
    }
}
