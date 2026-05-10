import Foundation

enum JSONPathComponent: Hashable, CustomStringConvertible {
    case key(String)
    case index(Int)

    var description: String {
        switch self {
        case .key(let key):
            return key
        case .index(let index):
            return "[\(index)]"
        }
    }
}

enum JSONScalarValue: Hashable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null

    init?(jsonValue: Any) {
        if jsonValue is NSNull {
            self = .null
        } else if let bool = jsonValue as? Bool {
            self = .bool(bool)
        } else if let int = jsonValue as? Int {
            self = .int(int)
        } else if let double = jsonValue as? Double {
            self = .double(double)
        } else if let string = jsonValue as? String {
            self = .string(string)
        } else {
            return nil
        }
    }

    var jsonValue: Any {
        switch self {
        case .string(let value):
            return value
        case .int(let value):
            return value
        case .double(let value):
            return value
        case .bool(let value):
            return value
        case .null:
            return NSNull()
        }
    }

    var displayValue: String {
        switch self {
        case .string(let value):
            return value
        case .int(let value):
            return String(value)
        case .double(let value):
            return String(value)
        case .bool(let value):
            return value ? "true" : "false"
        case .null:
            return "null"
        }
    }

    var typeName: String {
        switch self {
        case .string: return "String"
        case .int: return "Int"
        case .double: return "Double"
        case .bool: return "Bool"
        case .null: return "Null"
        }
    }

    func replacingValueText(_ text: String) -> JSONScalarValue {
        switch self {
        case .string:
            return .string(text)
        case .int:
            return .int(Int(text) ?? 0)
        case .double:
            return .double(Double(text) ?? 0)
        case .bool:
            return .bool(["true", "yes", "1", "on"].contains(text.lowercased()))
        case .null:
            return text.isEmpty || text.lowercased() == "null" ? .null : .string(text)
        }
    }
}

struct JSONScalarRow: Identifiable, Hashable {
    let id: String
    let path: [JSONPathComponent]
    let value: JSONScalarValue

    var pathString: String {
        JSONPathFormatter.string(from: path)
    }
}

enum JSONPathFormatter {
    static func string(from path: [JSONPathComponent]) -> String {
        var output = ""
        for component in path {
            switch component {
            case .key(let key):
                output += output.isEmpty ? key : ".\(key)"
            case .index(let index):
                output += "[\(index)]"
            }
        }
        return output
    }
}

enum JSONPathExplorer {
    static func scalarRows(in object: Any, limit: Int = 20_000) -> [JSONScalarRow] {
        var rows: [JSONScalarRow] = []
        walk(object, path: [], rows: &rows, limit: limit)
        return rows
    }

    static func summaryCounts(in object: Any) -> (objects: Int, arrays: Int, scalars: Int) {
        var objects = 0
        var arrays = 0
        var scalars = 0

        func walk(_ value: Any) {
            if let dictionary = value as? [String: Any] {
                objects += 1
                dictionary.values.forEach(walk)
            } else if let array = value as? [Any] {
                arrays += 1
                array.forEach(walk)
            } else {
                scalars += 1
            }
        }

        walk(object)
        return (objects, arrays, scalars)
    }

    private static func walk(_ value: Any, path: [JSONPathComponent], rows: inout [JSONScalarRow], limit: Int) {
        guard rows.count < limit else { return }

        if let dictionary = value as? [String: Any] {
            for key in dictionary.keys.sorted() {
                walk(dictionary[key] as Any, path: path + [.key(key)], rows: &rows, limit: limit)
            }
        } else if let array = value as? [Any] {
            for (index, item) in array.enumerated() {
                walk(item, path: path + [.index(index)], rows: &rows, limit: limit)
            }
        } else if let scalar = JSONScalarValue(jsonValue: value) {
            let pathString = JSONPathFormatter.string(from: path)
            rows.append(JSONScalarRow(id: pathString, path: path, value: scalar))
        }
    }
}

enum JSONPathEditor {
    static func updateValue(_ value: Any, in dictionary: inout [String: Any], at path: [JSONPathComponent]) {
        guard !path.isEmpty else { return }
        let updated = updateNode(dictionary, at: path, with: value)
        if let updatedDictionary = updated as? [String: Any] {
            dictionary = updatedDictionary
        }
    }

    private static func updateNode(_ node: Any, at path: [JSONPathComponent], with value: Any) -> Any {
        guard let head = path.first else { return value }
        let tail = Array(path.dropFirst())

        switch head {
        case .key(let key):
            var dictionary = node as? [String: Any] ?? [:]
            dictionary[key] = tail.isEmpty ? value : updateNode(dictionary[key] as Any, at: tail, with: value)
            return dictionary
        case .index(let index):
            var array = node as? [Any] ?? []
            guard array.indices.contains(index) else { return node }
            array[index] = tail.isEmpty ? value : updateNode(array[index], at: tail, with: value)
            return array
        }
    }
}
