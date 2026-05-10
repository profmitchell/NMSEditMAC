import SwiftUI

struct CatalogBrowserView: View {
    @StateObject private var catalog = GameCatalogStore()
    @State private var searchText = ""
    @State private var sourceFilter = "All"
    @State private var selectedEntry: GameCatalogEntry?

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search catalog", text: $searchText)
                            .textFieldStyle(.plain)
                    }

                    Picker("Source", selection: $sourceFilter) {
                        Text("All").tag("All")
                        ForEach(sources, id: \.self) { source in
                            Text(source.capitalized).tag(source)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                .padding(10)
                .background(.regularMaterial)

                List(filteredEntries, selection: $selectedEntry) { entry in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(entry.name)
                            .lineLimit(1)

                        Text("\(entry.id)  \(entry.source)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .tag(entry)
                }
                .listStyle(.sidebar)
            }
            .navigationSplitViewColumnWidth(min: 280, ideal: 360)
        } detail: {
            if let selectedEntry {
                VStack(alignment: .leading, spacing: 16) {
                    Text(selectedEntry.name)
                        .font(.title2.bold())

                    detailRow("ID", selectedEntry.id)
                    detailRow("Source", selectedEntry.source)
                    detailRow("Kind", selectedEntry.kind)

                    if !selectedEntry.category.isEmpty {
                        detailRow("Category", selectedEntry.category)
                    }

                    if !selectedEntry.subtitle.isEmpty {
                        detailRow("Subtitle", selectedEntry.subtitle)
                    }

                    if !selectedEntry.iconName.isEmpty {
                        detailRow("Icon", selectedEntry.iconName)
                    }

                    Spacer()
                }
                .padding(28)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else if let errorMessage = catalog.errorMessage {
                ContentUnavailableView("Catalog Error", systemImage: "exclamationmark.triangle", description: Text(errorMessage))
            } else {
                ContentUnavailableView("Select a Catalog Entry", systemImage: "books.vertical")
            }
        }
        .onAppear {
            catalog.loadIfNeeded()
        }
    }

    private var sources: [String] {
        Array(Set(catalog.entries.map(\.source))).sorted()
    }

    private var filteredEntries: [GameCatalogEntry] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return catalog.entries.filter { entry in
            let matchesSource = sourceFilter == "All" || entry.source == sourceFilter
            let matchesQuery = query.isEmpty || entry.searchText.contains(query)
            return matchesSource && matchesQuery
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.body, design: label == "ID" ? .monospaced : .default))
                .textSelection(.enabled)
        }
    }
}
