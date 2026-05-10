//
//  ContentView.swift
//  NMSEditMAC
//
//  Created by Mitchell Cohen on 5/10/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var saveManager = SaveManager()

    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Saves Folder")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    Text(saveManager.savesFolderPath)
                        .font(.caption2)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(saveManager.savesFolderPath)
                    
                    Button(action: { saveManager.chooseSavesFolder() }) {
                        Label("Change Folder", systemImage: "folder.badge.gearshape")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.top, 8)
                
                List(saveManager.saves, id: \.self, selection: $saveManager.selectedSaveURL) { url in
                    Label(url.lastPathComponent, systemImage: "doc.text.fill")
                        .padding(.vertical, 4)
                }
                .listStyle(.sidebar)
            }
            .navigationTitle("NMS Saves")
            .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 300)
            .toolbar {
                ToolbarItem {
                    Button(action: saveManager.refreshSaves) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
            }
        } detail: {
            if saveManager.selectedSaveURL != nil {
                if saveManager.isSaveLoaded {
                    VStack(spacing: 0) {
                        // Custom Header
                        HStack {
                            VStack(alignment: .leading) {
                                Text(saveManager.selectedSaveURL?.lastPathComponent ?? "Unknown")
                                    .font(.title2.weight(.bold))
                                Text("No Man's Sky Save Data")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if saveManager.isSaveLoaded {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(Color(NSColor.windowBackgroundColor))
                        
                        Divider()
                        
                        TabView {
                            SaveOverviewView(saveManager: saveManager)
                                .tabItem { Label("Overview", systemImage: "gauge.with.dots.needle.bottom.50percent") }

                            CurrencyEditorView(saveManager: saveManager)
                                .tabItem { Label("Currencies", systemImage: "dollarsign.circle.fill") }
                            
                            TeleporterView(saveManager: saveManager)
                                .tabItem { Label("Teleporter", systemImage: "map.fill") }

                            InventoryBrowserView(saveManager: saveManager)
                                .tabItem { Label("Inventory", systemImage: "shippingbox.fill") }
                            
                            ShipManagerView(saveManager: saveManager)
                                .tabItem { Label("Ships", systemImage: "airplane") }
                                
                            CorvetteDecoratorView(saveManager: saveManager)
                                .tabItem { Label("Corvette", systemImage: "wand.and.stars") }

                            CatalogBrowserView()
                                .tabItem { Label("Catalog", systemImage: "books.vertical") }

                            JSONInspectorView(saveManager: saveManager)
                                .tabItem { Label("Inspector", systemImage: "point.topleft.down.curvedto.point.bottomright.up") }

                            RawJSONEditorView(saveManager: saveManager)
                                .tabItem { Label("Raw JSON", systemImage: "curlybraces") }

                            BackupHistoryView(saveManager: saveManager)
                                .tabItem { Label("Backups", systemImage: "clock.arrow.circlepath") }
                        }
                        .padding()
                    }
                    .frame(minWidth: 500, minHeight: 400)
                } else if let error = saveManager.errorMessage {
                    ContentUnavailableView("Error Loading Save", systemImage: "exclamationmark.triangle", description: Text(error))
                } else {
                    ProgressView("Decrypting & Parsing JSON...")
                        .controlSize(.large)
                }
            } else {
                ContentUnavailableView("No Save Selected", systemImage: "tray.fill", description: Text("Please select a NMS JSON save file from the sidebar to begin editing."))
            }
        }
    }
}

#Preview {
    ContentView()
}
