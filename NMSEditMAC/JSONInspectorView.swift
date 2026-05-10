import SwiftUI

struct JSONInspectorView: View {
    @ObservedObject var saveManager: SaveManager

    @State private var searchText = ""
    @State private var selectedRow: JSONScalarRow?
    @State private var editedValue = ""
    @State private var rows: [JSONScalarRow] = []

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search JSON paths and values", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            .background(.regularMaterial)

            Divider()

            NavigationSplitView {
                List(filteredRows, selection: $selectedRow) { row in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(row.pathString)
                            .font(.system(.caption, design: .monospaced))
                            .lineLimit(1)
                        Text(row.value.displayValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .tag(row)
                }
                .listStyle(.sidebar)
                .navigationSplitViewColumnWidth(min: 260, ideal: 360)
            } detail: {
                if let selectedRow {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("JSON Value")
                            .font(.title2.bold())

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Path")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            Text(selectedRow.pathString)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text(selectedRow.value.typeName)
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            TextField("Value", text: $editedValue, axis: .vertical)
                                .font(.system(.body, design: .monospaced))
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(1...8)
                        }

                        HStack {
                            Button {
                                saveEditedValue()
                            } label: {
                                Label("Save Value", systemImage: "checkmark")
                            }
                            .buttonStyle(.borderedProminent)

                            Button {
                                editedValue = selectedRow.value.displayValue
                            } label: {
                                Label("Reset", systemImage: "arrow.uturn.backward")
                            }
                        }

                        Spacer()
                    }
                    .padding(28)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                } else {
                    ContentUnavailableView("No Value Selected", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                }
            }
        }
        .onAppear(perform: reloadRows)
        .onChange(of: saveManager.isSaveLoaded) { _, _ in reloadRows() }
        .onChange(of: selectedRow) { _, row in
            editedValue = row?.value.displayValue ?? ""
        }
    }

    private var filteredRows: [JSONScalarRow] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return rows }
        let query = trimmed.lowercased()
        return rows.filter {
            $0.pathString.lowercased().contains(query) ||
            $0.value.displayValue.lowercased().contains(query) ||
            $0.value.typeName.lowercased().contains(query)
        }
    }

    private func reloadRows() {
        guard let data = saveManager.currentSaveData else {
            rows = []
            selectedRow = nil
            return
        }
        rows = JSONPathExplorer.scalarRows(in: data)
        selectedRow = nil
    }

    private func saveEditedValue() {
        guard let selectedRow else { return }
        let newValue = selectedRow.value.replacingValueText(editedValue)
        saveManager.updateScalarValue(newValue, at: selectedRow.path)
        saveManager.saveChanges()
        reloadRows()
    }
}
