import Foundation

struct InventoryContainer: Identifiable, Hashable {
    let id: String
    let path: [JSONPathComponent]
    let name: String
    let slots: [InventorySlot]

    var pathString: String {
        JSONPathFormatter.string(from: path)
    }
}

struct InventorySlot: Identifiable, Hashable {
    let id: String
    let path: [JSONPathComponent]
    let itemID: String
    let type: String
    let amount: Int
    let maxAmount: Int
    let x: Int
    let y: Int
    let damaged: Bool
}

enum InventoryExplorer {
    static func containers(in object: Any) -> [InventoryContainer] {
        var containers: [InventoryContainer] = []
        walk(object, path: [], containers: &containers)
        return containers.sorted { lhs, rhs in
            lhs.pathString.localizedCaseInsensitiveCompare(rhs.pathString) == .orderedAscending
        }
    }

    private static func walk(_ value: Any, path: [JSONPathComponent], containers: inout [InventoryContainer]) {
        if let dictionary = value as? [String: Any] {
            if let slots = dictionary["Slots"] as? [[String: Any]] {
                let slotModels = slots.enumerated().compactMap { index, slot -> InventorySlot? in
                    guard let itemID = slot["Id"] as? String else { return nil }
                    let typeDictionary = slot["Type"] as? [String: Any]
                    let inventoryType = typeDictionary?["InventoryType"] as? String ?? "Unknown"
                    let indexDictionary = slot["Index"] as? [String: Any]
                    let x = indexDictionary?["X"] as? Int ?? 0
                    let y = indexDictionary?["Y"] as? Int ?? 0
                    let amount = slot["Amount"] as? Int ?? 0
                    let maxAmount = slot["MaxAmount"] as? Int ?? 0
                    let damageFactor = slot["DamageFactor"] as? Double ?? 0

                    return InventorySlot(
                        id: JSONPathFormatter.string(from: path + [.key("Slots"), .index(index)]),
                        path: path + [.key("Slots"), .index(index)],
                        itemID: itemID,
                        type: inventoryType,
                        amount: amount,
                        maxAmount: maxAmount,
                        x: x,
                        y: y,
                        damaged: damageFactor > 0
                    )
                }

                if !slotModels.isEmpty {
                    let name = dictionary["Name"] as? String
                    containers.append(InventoryContainer(
                        id: JSONPathFormatter.string(from: path),
                        path: path,
                        name: name?.isEmpty == false ? name! : path.last?.description ?? "Inventory",
                        slots: slotModels
                    ))
                }
            }

            for key in dictionary.keys.sorted() {
                walk(dictionary[key] as Any, path: path + [.key(key)], containers: &containers)
            }
        } else if let array = value as? [Any] {
            for (index, item) in array.enumerated() {
                walk(item, path: path + [.index(index)], containers: &containers)
            }
        }
    }
}
