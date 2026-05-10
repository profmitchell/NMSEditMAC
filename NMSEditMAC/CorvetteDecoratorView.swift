import SwiftUI

struct CorvetteDecoratorView: View {
    @ObservedObject var saveManager: SaveManager
    
    @State private var bases: [[String: Any]] = []
    @State private var donorIndex: Int = 0
    @State private var targetIndex: Int = 0
    
    @State private var logOutput = ""
    @State private var successMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Automated Corvette Decorator")
                    .font(.title2.bold())
                
                Text("Natively clones interior design from a Donor ship to a Target ship using surface-aware logic.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if bases.isEmpty {
                    Text("No PlayerShipBases found in this save.")
                        .foregroundColor(.red)
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        Picker("Donor Ship (Source)", selection: $donorIndex) {
                            ForEach(0..<bases.count, id: \.self) { i in
                                Text(baseLabel(for: bases[i])).tag(i)
                            }
                        }
                        
                        Picker("Target Ship (Destination)", selection: $targetIndex) {
                            ForEach(0..<bases.count, id: \.self) { i in
                                Text(baseLabel(for: bases[i])).tag(i)
                            }
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(12)
                    
                    Button(action: runNativeDecorator) {
                        Text("Regenerate Interior Furnishings")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(bases.isEmpty || donorIndex == targetIndex)
                }
                
                if let msg = successMessage {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text(msg)
                    }
                    .foregroundColor(.green)
                    .font(.headline)
                }
                
                if !logOutput.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Process Logs")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        
                        Text(logOutput)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.black.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(40)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .onAppear { loadBases() }
        .onChange(of: saveManager.isSaveLoaded) { _, isLoaded in
            if isLoaded { loadBases() }
        }
    }
    
    private func loadBases() {
        if let allBases: [[String: Any]] = saveManager.getValue(for: ["BaseContext", "PlayerStateData", "PersistentPlayerBases"]) {
            // Include PlayerShipBase and FreighterBase
            self.bases = allBases.compactMap { base in
                guard let typeObj = base["BaseType"] as? [String: Any],
                      let type = typeObj["PersistentBaseTypes"] as? String else { return nil }
                
                if type == "PlayerShipBase" || type == "FreighterBase" {
                    return base
                }
                return nil
            }
            if !bases.isEmpty {
                donorIndex = 0
                targetIndex = min(1, bases.count - 1)
            }
        } else {
            self.bases = []
        }
    }
    
    private func baseLabel(for base: [String: Any]) -> String {
        let name = base["Name"] as? String ?? ""
        let typeObj = base["BaseType"] as? [String: Any]
        let type = typeObj?["PersistentBaseTypes"] as? String ?? "Unknown"
        
        let displayName = name.isEmpty || name == "Default" ? "Unnamed \(type)" : name
        return displayName
    }
    
    private func runNativeDecorator() {
        guard donorIndex < bases.count, targetIndex < bases.count else { return }
        
        let donor = bases[donorIndex]
        var target = bases[targetIndex]
        
        logOutput = "Starting native decorator...\n"
        successMessage = nil
        
        do {
            let log = try CorvetteDecoratorLogic.applyDecorator(donorBase: donor, targetBase: &target)
            logOutput += log
            
            // Re-inject target back into allBases
            if var allBases: [[String: Any]] = saveManager.getValue(for: ["BaseContext", "PlayerStateData", "PersistentPlayerBases"]) {
                // Find target in allBases by matching Name or OriginalBaseVersion
                if let idx = allBases.firstIndex(where: { ($0["Name"] as? String) == (target["Name"] as? String) }) {
                    allBases[idx] = target
                    saveManager.updateValue(allBases, for: ["BaseContext", "PlayerStateData", "PersistentPlayerBases"])
                    saveManager.saveChanges()
                    successMessage = "Interior injected and saved natively!"
                    loadBases() // refresh UI
                } else {
                    logOutput += "\nFailed to map target back to master array."
                }
            }
        } catch {
            logOutput += "\nError: \(error.localizedDescription)"
        }
    }
}
