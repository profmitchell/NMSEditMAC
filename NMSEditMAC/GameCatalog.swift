import Foundation
import Combine

struct GameCatalogEntry: Identifiable, Hashable {
    let id: String
    let source: String
    let kind: String
    let name: String
    let subtitle: String
    let category: String
    let iconName: String

    var searchText: String {
        "\(id) \(source) \(kind) \(name) \(subtitle) \(category)".lowercased()
    }
}

final class GameCatalogStore: ObservableObject {
    @Published private(set) var entries: [GameCatalogEntry] = []
    @Published private(set) var errorMessage: String?

    func loadIfNeeded() {
        guard entries.isEmpty else { return }
        load()
    }

    func load() {
        do {
            entries = try GameCatalogLoader.loadCatalog()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

enum GameCatalogLoader {
    static func loadCatalog() throws -> [GameCatalogEntry] {
        guard let dbURL = locateDatabaseFolder() else {
            throw CatalogError.databaseNotFound
        }

        let files = ["items.xml", "rewards.xml", "words.xml", "frigates.xml", "settlements.xml"]
        var loadedEntries: [GameCatalogEntry] = []
        for fileName in files {
            let url = dbURL.appendingPathComponent(fileName)
            let source = fileName.replacingOccurrences(of: ".xml", with: "")
            loadedEntries.append(contentsOf: (try? parse(url: url, source: source)) ?? [])
        }

        return loadedEntries
        .sorted { lhs, rhs in
            lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    private static func locateDatabaseFolder() -> URL? {
        let fileURL = URL(fileURLWithPath: #filePath)
        let sourceRoot = fileURL.deletingLastPathComponent().deletingLastPathComponent()
        let candidates = [
            sourceRoot.appendingPathComponent("db_updater/nomanssave/db"),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("db_updater/nomanssave/db"),
            Bundle.main.resourceURL?.appendingPathComponent("nomanssave/db")
        ].compactMap { $0 }

        return candidates.first { FileManager.default.fileExists(atPath: $0.path) }
    }

    private static func parse(url: URL, source: String) throws -> [GameCatalogEntry] {
        let parser = XMLParser(contentsOf: url)
        let delegate = CatalogXMLDelegate(source: source)
        parser?.delegate = delegate

        guard parser?.parse() == true else {
            throw CatalogError.parseFailed(url.lastPathComponent)
        }

        return delegate.entries
    }
}

final class CatalogXMLDelegate: NSObject, XMLParserDelegate {
    private let source: String
    private(set) var entries: [GameCatalogEntry] = []

    init(source: String) {
        self.source = source
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        guard let id = attributeDict["id"] else { return }
        let rawName = attributeDict["name"] ?? attributeDict["text"] ?? id
        let name = rawName
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&amp;", with: "&")

        entries.append(GameCatalogEntry(
            id: id,
            source: source,
            kind: elementName,
            name: name,
            subtitle: attributeDict["subtitle"] ?? "",
            category: attributeDict["category"] ?? attributeDict["race"] ?? "",
            iconName: attributeDict["icon"] ?? ""
        ))
    }
}

enum CatalogError: LocalizedError {
    case databaseNotFound
    case parseFailed(String)

    var errorDescription: String? {
        switch self {
        case .databaseNotFound:
            return "Could not find db_updater/nomanssave/db."
        case .parseFailed(let fileName):
            return "Failed to parse \(fileName)."
        }
    }
}
