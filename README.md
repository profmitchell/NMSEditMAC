# NMSEditMAC

NMSEditMAC is a native macOS save editor for No Man's Sky. It is being built as a SwiftUI replacement for the older Java-based NMSSaveEditor workflow, with native Mac file handling, automatic backups, searchable JSON editing, and focused save-editing panels.

## Current Features

- Native SwiftUI macOS app
- Save folder discovery and JSON save loading
- Automatic backup before every write
- Manual backup creation and backup history browser
- Save overview dashboard with object, array, and scalar counts
- Currency editor for Units, Nanites, and Quicksilver
- Portal/teleporter coordinate editor
- Inventory browser that discovers inventory containers and slot contents
- Ship stats editor with ship import/export
- Corvette decorator workflow
- Catalog browser backed by No Man's Sky item/reward/word database XML
- Searchable JSON path inspector for editing scalar values
- Raw JSON editor with validation and save-back
- Project-local build and run script for repeatable development

## Requirements

- macOS 15.7 or newer, matching the current Xcode project deployment target
- Xcode 26.2 or newer
- No Java runtime is required for the native SwiftUI app

## Build And Run

From the repository root:

```bash
./script/build_and_run.sh
```

To build, launch, and verify the app process:

```bash
./script/build_and_run.sh --verify
```

The debug build is produced at:

```text
build/DerivedData/Build/Products/Debug/NMSEditMAC.app
```

## Project Layout

```text
NMSEditMAC/
  ContentView.swift              Main split-view shell and editor tabs
  SaveManager.swift              Save loading, writing, backups, import/export
  SaveOverviewView.swift         Summary and quick actions
  CurrencyEditorView.swift       Currency editing
  TeleporterView.swift           Portal coordinate editing
  InventoryBrowserView.swift     Inventory container browser
  ShipManagerView.swift          Ship stats and import/export
  CorvetteDecoratorView.swift    Corvette interior helper UI
  JSONInspectorView.swift        Searchable path-based JSON scalar editor
  RawJSONEditorView.swift        Full raw JSON editor
  CatalogBrowserView.swift       XML database browser
script/
  build_and_run.sh               Build and launch helper
  package_legacy_mac_app.sh      Optional wrapper for the legacy Java editor
db_updater/nomanssave/db/        XML catalog data used by the native app
```

## Safety

NMSEditMAC creates a timestamped backup next to the selected save before writing changes. Backups are stored in:

```text
NMSEditMAC Backups/
```

Do not publish real save files, backup files, logs, or local configuration. The repository ignores those local artifacts by default.

## Legacy Java Editor

This repository may be used alongside a local copy of the legacy Java `NMSSaveEditor.jar`, but the native app does not require Java. The helper script below can package a local legacy jar as a macOS `.app` wrapper when the jar is present locally:

```bash
./script/package_legacy_mac_app.sh
```

The generated wrapper is a local artifact and is not intended to be committed.

## Status

This is an active native replacement effort. Specialized Java-editor panels are being rebuilt incrementally, while the raw JSON editor and JSON inspector provide full-save access for fields that do not yet have dedicated native UI.
