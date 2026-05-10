import SwiftUI
import AppKit

struct BackupHistoryView: View {
    @ObservedObject var saveManager: SaveManager
    @State private var backups: [URL] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Backups")
                    .font(.title2.bold())

                Spacer()

                Button {
                    saveManager.createManualBackup()
                    reload()
                } label: {
                    Label("New Backup", systemImage: "plus")
                }

                Button {
                    reload()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }

            if backups.isEmpty {
                ContentUnavailableView("No Backups", systemImage: "clock.arrow.circlepath")
            } else {
                List(backups, id: \.self) { url in
                    HStack {
                        Image(systemName: "doc.badge.clock")
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading) {
                            Text(url.lastPathComponent)
                                .lineLimit(1)
                            Text(url.deletingLastPathComponent().path)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Button {
                            NSWorkspace.shared.activateFileViewerSelecting([url])
                        } label: {
                            Image(systemName: "finder")
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
        .padding(28)
        .onAppear(perform: reload)
        .onChange(of: saveManager.lastBackupURL) { _, _ in reload() }
        .onChange(of: saveManager.selectedSaveURL) { _, _ in reload() }
    }

    private func reload() {
        backups = saveManager.recentBackups()
    }
}
