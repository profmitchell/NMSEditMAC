import SwiftUI

struct RawJSONEditorView: View {
    @ObservedObject var saveManager: SaveManager

    @State private var text = ""
    @State private var validationMessage = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    reload()
                } label: {
                    Label("Reload", systemImage: "arrow.clockwise")
                }

                Button {
                    validate()
                } label: {
                    Label("Validate", systemImage: "checkmark.seal")
                }

                Button {
                    save()
                } label: {
                    Label("Save JSON", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)

                Spacer()

                Text(validationMessage)
                    .font(.caption)
                    .foregroundStyle(validationMessage.hasPrefix("Valid") ? .green : .secondary)
            }
            .padding(10)

            Divider()

            TextEditor(text: $text)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(12)
        }
        .onAppear(perform: reload)
        .onChange(of: saveManager.isSaveLoaded) { _, _ in reload() }
    }

    private func reload() {
        text = saveManager.rawJSONString()
        validationMessage = text.isEmpty ? "" : "Loaded"
    }

    private func validate() {
        do {
            _ = try JSONSerialization.jsonObject(with: Data(text.utf8))
            validationMessage = "Valid JSON"
        } catch {
            validationMessage = error.localizedDescription
        }
    }

    private func save() {
        do {
            try saveManager.replaceCurrentSave(with: text)
            validationMessage = "Valid JSON, saved"
        } catch {
            validationMessage = error.localizedDescription
            saveManager.errorMessage = "Failed to save raw JSON: \(error.localizedDescription)"
        }
    }
}
