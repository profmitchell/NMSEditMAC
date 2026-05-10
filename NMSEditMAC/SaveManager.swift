import Foundation
import Combine
import AppKit
import UniformTypeIdentifiers

class SaveManager: ObservableObject {
    @Published var saves: [URL] = []
    @Published var selectedSaveURL: URL? {
        didSet {
            loadSelectedSave()
        }
    }
    
    @Published var currentSaveData: [String: Any]?
    @Published var isSaveLoaded: Bool = false
    @Published var errorMessage: String?
    @Published var statusMessage: String?
    @Published var lastBackupURL: URL?
    @Published var selectedSaveKind: SaveFileKind = .unknown
    
    @Published var savesFolderPath: String {
        didSet {
            UserDefaults.standard.set(savesFolderPath, forKey: "savesFolderPath")
            refreshSaves()
        }
    }
    
    init() {
        let defaultSavesPath = SaveManager.defaultSavesFolder()
        self.savesFolderPath = UserDefaults.standard.string(forKey: "savesFolderPath") ?? defaultSavesPath
        refreshSaves()
    }
    
    func chooseSavesFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select your No Man's Sky saves folder"
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                self.savesFolderPath = url.path
            }
        }
    }
    
    func refreshSaves() {
        let fileManager = FileManager.default
        let url = URL(fileURLWithPath: savesFolderPath)
        
        var foundSaves: [URL] = []
        if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.contentModificationDateKey], options: [.skipsHiddenFiles]) {
            for case let fileURL as URL in enumerator {
                let lowercasedName = fileURL.lastPathComponent.lowercased()
                let supportedExtensions = ["json", "hg"]
                if supportedExtensions.contains(fileURL.pathExtension.lowercased()),
                   !lowercasedName.hasPrefix("mf_") {
                    foundSaves.append(fileURL)
                }
            }
        }

        foundSaves.sort { lhs, rhs in
            let leftDate = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let rightDate = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return leftDate > rightDate
        }
        
        DispatchQueue.main.async {
            self.saves = foundSaves
            if foundSaves.isEmpty {
                self.errorMessage = "No .json saves found in \(url.lastPathComponent) or its subfolders."
            } else {
                self.errorMessage = nil
            }
        }
    }
    
    private func loadSelectedSave() {
        guard let url = selectedSaveURL else {
            currentSaveData = nil
            isSaveLoaded = false
            errorMessage = nil
            statusMessage = nil
            selectedSaveKind = .unknown
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            selectedSaveKind = classifySaveData(data, url: url)
            guard selectedSaveKind.isJSONReadable else {
                DispatchQueue.main.async {
                    self.currentSaveData = nil
                    self.isSaveLoaded = false
                    self.errorMessage = "This is a binary .hg save. Native .hg decode/encode is not implemented yet. Use the legacy editor to export JSON, or select an exported .json save."
                    self.statusMessage = nil
                }
                return
            }

            if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                DispatchQueue.main.async {
                    self.currentSaveData = json
                    self.isSaveLoaded = true
                    self.errorMessage = nil
                    self.statusMessage = "Loaded \(url.lastPathComponent)"
                }
            } else {
                DispatchQueue.main.async {
                    self.isSaveLoaded = false
                    self.errorMessage = "Failed to parse save JSON structure."
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isSaveLoaded = false
                self.errorMessage = "Failed to read save file: \(error.localizedDescription)"
            }
        }
    }
    
    func saveChanges() {
        guard let url = selectedSaveURL, let data = currentSaveData else { return }
        
        do {
            let backupURL = try createBackup(for: url)
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: [.prettyPrinted])
            try jsonData.write(to: url)
            lastBackupURL = backupURL
            statusMessage = "Saved \(url.lastPathComponent)"
        } catch {
            errorMessage = "Failed to write save back to disk: \(error.localizedDescription)"
        }
    }

    func rawJSONString() -> String {
        guard let data = currentSaveData,
              JSONSerialization.isValidJSONObject(data),
              let jsonData = try? JSONSerialization.data(withJSONObject: data, options: [.prettyPrinted, .sortedKeys]),
              let string = String(data: jsonData, encoding: .utf8) else {
            return ""
        }
        return string
    }

    func replaceCurrentSave(with rawJSONString: String) throws {
        guard let selectedSaveURL else { return }
        guard selectedSaveKind.isJSONWritable else {
            throw SaveManagerError.binaryHGImportUnsupported
        }
        let data = Data(rawJSONString.utf8)
        let object = try JSONSerialization.jsonObject(with: data, options: [.mutableContainers])
        guard let dictionary = object as? [String: Any] else {
            throw SaveManagerError.invalidRootObject
        }

        let backupURL = try createBackup(for: selectedSaveURL)
        try data.write(to: selectedSaveURL)

        currentSaveData = dictionary
        isSaveLoaded = true
        lastBackupURL = backupURL
        statusMessage = "Saved raw JSON for \(selectedSaveURL.lastPathComponent)"
    }

    func importJSONReplacingCurrentSave() {
        guard selectedSaveURL != nil else { return }
        guard selectedSaveKind.isJSONWritable else {
            errorMessage = "Import JSON cannot be applied directly to a binary .hg save yet. Select an exported JSON save, or use the legacy editor until native .hg encoding is added."
            return
        }

        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.message = "Choose a JSON file to apply to the selected save."

        if panel.runModal() == .OK, let url = panel.url {
            do {
                let text = try String(contentsOf: url, encoding: .utf8)
                try replaceCurrentSave(with: text)
                statusMessage = "Imported \(url.lastPathComponent)"
            } catch {
                errorMessage = "Failed to import JSON: \(error.localizedDescription)"
            }
        }
    }

    func createManualBackup() {
        guard let selectedSaveURL else { return }
        do {
            lastBackupURL = try createBackup(for: selectedSaveURL)
            statusMessage = "Created backup \(lastBackupURL?.lastPathComponent ?? "")"
        } catch {
            errorMessage = "Failed to create backup: \(error.localizedDescription)"
        }
    }

    func revealSelectedSave() {
        guard let selectedSaveURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([selectedSaveURL])
    }

    func exportCurrentSave() {
        guard let selectedSaveURL, let data = currentSaveData else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = selectedSaveURL.deletingPathExtension().lastPathComponent + ".export.json"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data, options: [.prettyPrinted, .sortedKeys])
                try jsonData.write(to: url)
                statusMessage = "Exported \(url.lastPathComponent)"
            } catch {
                errorMessage = "Failed to export save: \(error.localizedDescription)"
            }
        }
    }

    func backupFolderURL(for saveURL: URL? = nil) -> URL? {
        guard let saveURL = saveURL ?? selectedSaveURL else { return nil }
        return saveURL.deletingLastPathComponent().appendingPathComponent("NMSEditMAC Backups", isDirectory: true)
    }

    func recentBackups() -> [URL] {
        guard let folder = backupFolderURL() else { return [] }
        let contents = (try? FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        return contents.sorted { lhs, rhs in
            let leftDate = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let rightDate = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return leftDate > rightDate
        }
    }
    
    // MARK: - Safe Extractors
    func getValue<T>(for keyPath: [String]) -> T? {
        var current: Any? = currentSaveData
        for key in keyPath {
            if let dict = current as? [String: Any] {
                current = dict[key]
            } else {
                return nil
            }
        }
        return current as? T
    }
    
    func updateValue(_ value: Any, for keyPath: [String]) {
        guard !keyPath.isEmpty, var data = currentSaveData else { return }
        
        func updateNestedDictionary(dict: inout [String: Any], keys: [String], newValue: Any) {
            let key = keys[0]
            if keys.count == 1 {
                dict[key] = newValue
            } else {
                var nestedDict = dict[key] as? [String: Any] ?? [String: Any]()
                let remainingKeys = Array(keys.dropFirst())
                updateNestedDictionary(dict: &nestedDict, keys: remainingKeys, newValue: newValue)
                dict[key] = nestedDict
            }
        }
        
        updateNestedDictionary(dict: &data, keys: keyPath, newValue: value)
        currentSaveData = data
    }

    func updateScalarValue(_ value: JSONScalarValue, at path: [JSONPathComponent]) {
        guard var data = currentSaveData else { return }
        JSONPathEditor.updateValue(value.jsonValue, in: &data, at: path)
        currentSaveData = data
    }

    private func createBackup(for url: URL) throws -> URL {
        let fileManager = FileManager.default
        let folder = backupFolderURL(for: url)!
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        let timestamp = formatter.string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let backupName = "\(url.deletingPathExtension().lastPathComponent).\(timestamp).json"
        let backupURL = folder.appendingPathComponent(backupName)
        try fileManager.copyItem(at: url, to: backupURL)
        return backupURL
    }

    private func classifySaveData(_ data: Data, url: URL) -> SaveFileKind {
        let trimmedPrefix = data.prefix(64).drop { byte in
            byte == 0x20 || byte == 0x09 || byte == 0x0A || byte == 0x0D
        }
        let firstByte = trimmedPrefix.first

        if firstByte == UInt8(ascii: "{") || firstByte == UInt8(ascii: "[") {
            return url.pathExtension.lowercased() == "hg" ? .jsonHG : .json
        }

        if url.pathExtension.lowercased() == "hg" {
            return .binaryHG
        }

        return .unknown
    }

    static func defaultSavesFolder() -> String {
        let helloGames = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/HelloGames/NMS", isDirectory: true)
        if FileManager.default.fileExists(atPath: helloGames.path) {
            return helloGames.path
        }
        return "/Users/Shared/CohenConcepts/NMS-AI-Builder/data/saves"
    }
}

enum SaveManagerError: LocalizedError {
    case invalidRootObject
    case binaryHGImportUnsupported

    var errorDescription: String? {
        switch self {
        case .invalidRootObject:
            return "The root JSON value must be an object."
        case .binaryHGImportUnsupported:
            return "Direct JSON import into binary .hg saves is not implemented yet."
        }
    }
}

enum SaveFileKind {
    case json
    case jsonHG
    case binaryHG
    case unknown

    var isJSONReadable: Bool {
        switch self {
        case .json, .jsonHG:
            return true
        case .binaryHG, .unknown:
            return false
        }
    }

    var isJSONWritable: Bool {
        isJSONReadable
    }

    var label: String {
        switch self {
        case .json:
            return "JSON"
        case .jsonHG:
            return "JSON .hg"
        case .binaryHG:
            return "Binary .hg"
        case .unknown:
            return "Unknown"
        }
    }
}
