import SwiftUI

struct InventoryBrowserView: View {
    @ObservedObject var saveManager: SaveManager

    @State private var containers: [InventoryContainer] = []
    @State private var selectedContainer: InventoryContainer?
    @State private var searchText = ""

    var body: some View {
        NavigationSplitView {
            List(filteredContainers, selection: $selectedContainer) { container in
                VStack(alignment: .leading, spacing: 3) {
                    Text(container.name)
                        .lineLimit(1)
                    Text("\(container.slots.count) slots  \(container.pathString)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .tag(container)
            }
            .safeAreaInset(edge: .top) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search inventories", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(10)
                .background(.regularMaterial)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 280, ideal: 360)
        } detail: {
            if let selectedContainer {
                VStack(alignment: .leading, spacing: 14) {
                    Text(selectedContainer.name)
                        .font(.title2.bold())
                    Text(selectedContainer.pathString)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)

                    Table(selectedContainer.slots) {
                        TableColumn("ID") { slot in
                            Text(slot.itemID)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                        }

                        TableColumn("Type") { slot in
                            Text(slot.type)
                        }

                        TableColumn("Amount") { slot in
                            Text("\(slot.amount)")
                                .monospacedDigit()
                        }

                        TableColumn("Max") { slot in
                            Text("\(slot.maxAmount)")
                                .monospacedDigit()
                        }

                        TableColumn("Slot") { slot in
                            Text("\(slot.x), \(slot.y)")
                                .monospacedDigit()
                        }

                        TableColumn("State") { slot in
                            Text(slot.damaged ? "Damaged" : "OK")
                                .foregroundStyle(slot.damaged ? .orange : .secondary)
                        }
                    }
                }
                .padding(24)
            } else {
                ContentUnavailableView("No Inventory Selected", systemImage: "shippingbox")
            }
        }
        .onAppear(perform: reload)
        .onChange(of: saveManager.isSaveLoaded) { _, _ in reload() }
    }

    private var filteredContainers: [InventoryContainer] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return containers }
        return containers.filter {
            $0.name.lowercased().contains(query) ||
            $0.pathString.lowercased().contains(query) ||
            $0.slots.contains { slot in
                slot.itemID.lowercased().contains(query) || slot.type.lowercased().contains(query)
            }
        }
    }

    private func reload() {
        guard let data = saveManager.currentSaveData else {
            containers = []
            selectedContainer = nil
            return
        }
        containers = InventoryExplorer.containers(in: data)
        selectedContainer = containers.first
    }
}
