import SwiftUI

struct SaveOverviewView: View {
    @ObservedObject var saveManager: SaveManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Save Overview")
                    .font(.title2.bold())

                if let selectedSaveURL = saveManager.selectedSaveURL {
                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 16) {
                        GridRow {
                            metricCard("File", selectedSaveURL.lastPathComponent, "doc.text")
                            metricCard("Format", saveManager.selectedSaveKind.label, "doc.badge.gearshape")
                            metricCard("Ships", "\(shipCount)", "airplane")
                        }

                        GridRow {
                            metricCard("Bases", "\(baseCount)", "house")
                            metricCard("Objects", "\(summary.objects)", "curlybraces")
                            metricCard("Arrays", "\(summary.arrays)", "list.bullet")
                            metricCard("Values", "\(summary.scalars)", "number")
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Actions")
                            .font(.headline)

                        HStack {
                            Button {
                                saveManager.createManualBackup()
                            } label: {
                                Label("Backup", systemImage: "clock.arrow.circlepath")
                            }

                            Button {
                                saveManager.exportCurrentSave()
                            } label: {
                                Label("Export", systemImage: "square.and.arrow.up")
                            }

                            Button {
                                saveManager.importJSONReplacingCurrentSave()
                            } label: {
                                Label("Import JSON", systemImage: "square.and.arrow.down")
                            }
                            .disabled(!saveManager.selectedSaveKind.isJSONWritable)

                            Button {
                                saveManager.revealSelectedSave()
                            } label: {
                                Label("Reveal", systemImage: "finder")
                            }
                        }
                        .buttonStyle(.bordered)

                        if let status = saveManager.statusMessage {
                            Label(status, systemImage: "checkmark.circle")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(28)
            .frame(maxWidth: 860, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }

    private var summary: (objects: Int, arrays: Int, scalars: Int) {
        guard let data = saveManager.currentSaveData else { return (0, 0, 0) }
        return JSONPathExplorer.summaryCounts(in: data)
    }

    private var shipCount: Int {
        let ships: [[String: Any]]? = saveManager.getValue(for: ["BaseContext", "PlayerStateData", "ShipOwnership"])
        return ships?.count ?? 0
    }

    private var baseCount: Int {
        let bases: [[String: Any]]? = saveManager.getValue(for: ["BaseContext", "PlayerStateData", "PersistentPlayerBases"])
        return bases?.count ?? 0
    }

    private func metricCard(_ title: String, _ value: String, _ systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title2.bold())
                .lineLimit(1)
                .truncationMode(.middle)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 180, alignment: .leading)
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
