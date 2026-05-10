import SwiftUI

struct CurrencyEditorView: View {
    @ObservedObject var saveManager: SaveManager
    
    // Local state for UI bindings
    @State private var units: Int = -1
    @State private var nanites: Int = -1
    @State private var specials: Int = -1
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Player Currencies")
                    .font(.title2.bold())
                
                VStack(alignment: .leading, spacing: 12) {
                    labeledField("Units", value: $units)
                    labeledField("Nanites", value: $nanites)
                    labeledField("Quicksilver", value: $specials)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .cornerRadius(12)
                
                Button(action: {
                    saveManager.updateValue(units, for: ["BaseContext", "PlayerStateData", "Units"])
                    saveManager.updateValue(nanites, for: ["BaseContext", "PlayerStateData", "Nanites"])
                    saveManager.updateValue(specials, for: ["BaseContext", "PlayerStateData", "Specials"])
                    saveManager.saveChanges()
                }) {
                    Text("Save Changes")
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
                .frame(width: 150)
        }
    }
    
    private func loadValues() {
        if let val: Int = saveManager.getValue(for: ["BaseContext", "PlayerStateData", "Units"]) { units = val }
        if let val: Int = saveManager.getValue(for: ["BaseContext", "PlayerStateData", "Nanites"]) { nanites = val }
        if let val: Int = saveManager.getValue(for: ["BaseContext", "PlayerStateData", "Specials"]) { specials = val }
    }
}
