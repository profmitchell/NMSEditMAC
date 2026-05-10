import SwiftUI

struct TeleporterView: View {
    @ObservedObject var saveManager: SaveManager
    
    @State private var realityIndex: Int = 0
    @State private var voxelX: Int = 0
    @State private var voxelY: Int = 0
    @State private var voxelZ: Int = 0
    @State private var solarSystemIndex: Int = 0
    @State private var planetIndex: Int = 0
    @State private var portalCode: String = ""
    
    let path = ["BaseContext", "PlayerStateData", "UniverseAddress"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Galactic Coordinates")
                    .font(.title2.bold())
                
                VStack(alignment: .leading, spacing: 12) {
                    labeledField("Galaxy (Reality Index)", value: $realityIndex)
                    
                    labeledTextField("Portal Glyph Code", text: $portalCode)
                        .font(.system(.body, design: .monospaced))
                        .onChange(of: portalCode) { _ in parsePortalCode() }
                    
                    Divider().padding(.vertical, 8)
                    
                    labeledField("Voxel X", value: $voxelX)
                        .onChange(of: voxelX) { _ in updatePortalCode() }
                    labeledField("Voxel Y", value: $voxelY)
                        .onChange(of: voxelY) { _ in updatePortalCode() }
                    labeledField("Voxel Z", value: $voxelZ)
                        .onChange(of: voxelZ) { _ in updatePortalCode() }
                    
                    labeledField("System Index", value: $solarSystemIndex)
                        .onChange(of: solarSystemIndex) { _ in updatePortalCode() }
                    labeledField("Planet Index", value: $planetIndex)
                        .onChange(of: planetIndex) { _ in updatePortalCode() }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .cornerRadius(12)
                
                Button(action: {
                    saveManager.updateValue(realityIndex, for: path + ["RealityIndex"])
                    saveManager.updateValue(voxelX, for: path + ["GalacticAddress", "VoxelX"])
                    saveManager.updateValue(voxelY, for: path + ["GalacticAddress", "VoxelY"])
                    saveManager.updateValue(voxelZ, for: path + ["GalacticAddress", "VoxelZ"])
                    saveManager.updateValue(solarSystemIndex, for: path + ["GalacticAddress", "SolarSystemIndex"])
                    saveManager.updateValue(planetIndex, for: path + ["GalacticAddress", "PlanetIndex"])
                    saveManager.saveChanges()
                }) {
                    Text("Save Coordinates")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(40)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            loadValues()
        }
        .onChange(of: saveManager.isSaveLoaded) { _, isLoaded in
            if isLoaded {
                loadValues()
            }
        }
    }
    
    @ViewBuilder
    private func labeledField(_ label: String, value: Binding<Int>) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            TextField("", value: value, format: .number)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .frame(width: 120)
        }
    }
    
    @ViewBuilder
    private func labeledTextField(_ label: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            TextField("", text: text)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .frame(width: 200)
        }
    }
    
    private func loadValues() {
        if let val: Int = saveManager.getValue(for: path + ["RealityIndex"]) { realityIndex = val }
        if let val: Int = saveManager.getValue(for: path + ["GalacticAddress", "VoxelX"]) { voxelX = val }
        if let val: Int = saveManager.getValue(for: path + ["GalacticAddress", "VoxelY"]) { voxelY = val }
        if let val: Int = saveManager.getValue(for: path + ["GalacticAddress", "VoxelZ"]) { voxelZ = val }
        if let val: Int = saveManager.getValue(for: path + ["GalacticAddress", "SolarSystemIndex"]) { solarSystemIndex = val }
        if let val: Int = saveManager.getValue(for: path + ["GalacticAddress", "PlanetIndex"]) { planetIndex = val }
        updatePortalCode()
    }
    
    private func updatePortalCode() {
        let p = String(format: "%1X", max(0, min(15, planetIndex)))
        let sss = String(format: "%03X", max(0, min(4095, solarSystemIndex)))
        let yy = String(format: "%02X", max(0, min(255, voxelY + 127)))
        let zzz = String(format: "%03X", max(0, min(4095, voxelZ + 2047)))
        let xxx = String(format: "%03X", max(0, min(4095, voxelX + 2047)))
        let code = "\(p)\(sss)\(yy)\(zzz)\(xxx)"
        if portalCode != code {
            portalCode = code
        }
    }
    
    private func parsePortalCode() {
        let code = portalCode.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard code.count == 12 else { return }
        
        let pStr = String(code.prefix(1))
        let sssStr = String(code.dropFirst(1).prefix(3))
        let yyStr = String(code.dropFirst(4).prefix(2))
        let zzzStr = String(code.dropFirst(6).prefix(3))
        let xxxStr = String(code.dropFirst(9).prefix(3))
        
        if let p = Int(pStr, radix: 16) { planetIndex = p }
        if let sss = Int(sssStr, radix: 16) { solarSystemIndex = sss }
        if let yy = Int(yyStr, radix: 16) { voxelY = yy - 127 }
        if let zzz = Int(zzzStr, radix: 16) { voxelZ = zzz - 2047 }
        if let xxx = Int(xxxStr, radix: 16) { voxelX = xxx - 2047 }
    }
}
