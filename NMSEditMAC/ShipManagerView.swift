import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ShipManagerView: View {
    @ObservedObject var saveManager: SaveManager
    
    @State private var ships: [[String: Any]] = []
    @State private var selectedShipIndex: Int = 0
    
    // Stats
    @State private var hyperdrive: Double = 0.0
    @State private var damage: Double = 0.0
    @State private var shield: Double = 0.0
    @State private var agile: Double = 0.0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if ships.isEmpty {
                    Text("No ships found.")
                        .foregroundColor(.secondary)
                } else {
                    HStack {
                        Text("Ship Selection")
                            .font(.title2.bold())
                        Spacer()
                        Picker("", selection: $selectedShipIndex) {
                            ForEach(0..<ships.count, id: \.self) { index in
                                let shipName = ships[index]["Name"] as? String ?? "Unknown Ship"
                                Text("\(index + 1): \(shipName)").tag(index)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 250)
                        .onChange(of: selectedShipIndex) { _ in
                            loadStats()
                        }
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: exportSelectedShip) {
                            Label("Export Ship", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        Button(action: importShip) {
                            Label("Import Ship", systemImage: "square.and.arrow.down")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Divider().padding(.vertical, 8)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Base Stats")
                            .font(.headline)
                        
                        labeledField("Damage", value: $damage)
                        labeledField("Shield", value: $shield)
                        labeledField("Hyperdrive", value: $hyperdrive)
                        labeledField("Agility", value: $agile)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(12)
                    
                    Button(action: saveStats) {
                        Text("Save Ship Stats")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding(40)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            loadShips()
        }
        .onChange(of: saveManager.isSaveLoaded) { _, isLoaded in
            if isLoaded {
                loadShips()
            }
        }
    }
    
    @ViewBuilder
    private func labeledField(_ label: String, value: Binding<Double>) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            TextField("", value: value, format: .number)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .frame(width: 150)
        }
    }
    
    private func loadShips() {
        if let ownership: [[String: Any]] = saveManager.getValue(for: ["BaseContext", "PlayerStateData", "ShipOwnership"]) {
            self.ships = ownership
            if selectedShipIndex >= ships.count {
                selectedShipIndex = 0
            }
            loadStats()
        } else {
            self.ships = []
        }
    }
    
    private func loadStats() {
        guard selectedShipIndex < ships.count else { return }
        let ship = ships[selectedShipIndex]
        
        hyperdrive = 0.0
        damage = 0.0
        shield = 0.0
        agile = 0.0
        
        if let inventory = ship["Inventory"] as? [String: Any],
           let baseStats = inventory["BaseStatValues"] as? [[String: Any]] {
            for stat in baseStats {
                let statID = stat["BaseStatID"] as? String ?? ""
                let value = stat["Value"] as? Double ?? 0.0
                switch statID {
                case "^SHIP_HYPERDRIVE": hyperdrive = value
                case "^SHIP_DAMAGE": damage = value
                case "^SHIP_SHIELD": shield = value
                case "^SHIP_AGILE": agile = value
                default: break
                }
            }
        }
    }
    
    private func saveStats() {
        guard selectedShipIndex < ships.count else { return }
        var ship = ships[selectedShipIndex]
        
        if var inventory = ship["Inventory"] as? [String: Any],
           var baseStats = inventory["BaseStatValues"] as? [[String: Any]] {
            
            for i in 0..<baseStats.count {
                let statID = baseStats[i]["BaseStatID"] as? String ?? ""
                switch statID {
                case "^SHIP_HYPERDRIVE": baseStats[i]["Value"] = hyperdrive
                case "^SHIP_DAMAGE": baseStats[i]["Value"] = damage
                case "^SHIP_SHIELD": baseStats[i]["Value"] = shield
                case "^SHIP_AGILE": baseStats[i]["Value"] = agile
                default: break
                }
            }
            inventory["BaseStatValues"] = baseStats
            ship["Inventory"] = inventory
            ships[selectedShipIndex] = ship
            
            saveManager.updateValue(ships, for: ["BaseContext", "PlayerStateData", "ShipOwnership"])
            saveManager.saveChanges()
        }
    }
    
    private func exportSelectedShip() {
        guard selectedShipIndex < ships.count else { return }
        let ship = ships[selectedShipIndex]
        let shipName = ship["Name"] as? String ?? "ExportedShip"
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "\(shipName.replacingOccurrences(of: " ", with: "_")).json"
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try JSONSerialization.data(withJSONObject: ship, options: .prettyPrinted)
                try data.write(to: url)
                print("Exported ship to \(url)")
            } catch {
                print("Failed to export ship: \(error)")
            }
        }
    }
    
    private func importShip() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try Data(contentsOf: url)
                if let importedShip = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    // Overwrite selected ship slot
                    ships[selectedShipIndex] = importedShip
                    saveManager.updateValue(ships, for: ["BaseContext", "PlayerStateData", "ShipOwnership"])
                    saveManager.saveChanges()
                    loadStats()
                }
            } catch {
                print("Failed to import ship: \(error)")
            }
        }
    }
}
