import Foundation

class CorvetteDecoratorLogic {
    
    static let INTERIOR_ANCHOR_IDS = ["^B_HAB_B", "^B_COK_D", "^B_ALK_A"]
    static let TABLE_KEYWORDS = ["BUILDWORKTOP", "BUILDLIGHTTABLE", "TABLE", "WORKTOP", "COUNTER", "DESK", "BAR"]
    
    static let TARGET_ADDITIONS: [String: Int] = [
        "rug": 4, "chair": 6, "plant": 12, "crate": 4, "light": 4, "table_prop": 6, "poster": 4
    ]
    
    static let SKIPPED_CATEGORIES = ["wall_screen", "curtain", "decal"]
    
    static let SLOTS: [String: [[Double]]] = [
        "floor": [
            [1.8, 0.10, 1.8], [-1.8, 0.10, 1.8], [1.8, 0.10, -1.8], [-1.8, 0.10, -1.8],
            [1.8, 0.10, 0.0], [-1.8, 0.10, 0.0], [0.0, 0.10, 1.8], [0.0, 0.10, -1.8],
            [1.5, 0.10, 1.5], [-1.5, 0.10, 1.5], [1.5, 0.10, -1.5], [-1.5, 0.10, -1.5]
        ],
        "ceiling": [
            [1.0, 2.5, 1.0], [-1.0, 2.5, 1.0], [1.0, 2.5, -1.0], [-1.0, 2.5, -1.0], [0.0, 2.5, 0.0]
        ],
        "table": [
            [0.0, 0.85, 0.0], [0.35, 0.85, 0.0], [-0.35, 0.85, 0.0], [0.0, 0.85, 0.35], [0.0, 0.85, -0.35]
        ],
        "wall": [
            [1.9, 1.5, 0.0], [-1.9, 1.5, 0.0], [0.0, 1.5, 1.9], [0.0, 1.5, -1.9]
        ]
    ]
    
    static let CATEGORY_TO_SURFACE = [
        "rug": "floor", "chair": "floor", "plant": "floor", "crate": "floor",
        "light": "ceiling", "table_prop": "table", "poster": "wall"
    ]
    
    static let CATEGORY_ANCHOR_FILTER = [
        "rug": ["^B_HAB_B"],
        "plant": ["^B_HAB_B", "^B_ALK_A", "^B_COK_D"],
        "chair": ["^B_HAB_B"],
        "crate": ["^B_HAB_B", "^B_ALK_A"],
        "light": ["^B_HAB_B", "^B_COK_D", "^B_ALK_A"]
    ]
    
    static func loadSafeCategories() -> [String: String] {
        let path = "/Users/Shared/CohenConcepts/NMS-AI-Builder/data/library/safe_decor_parts.json"
        var map: [String: String] = [:]
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let objects = json["objects"] as? [[String: Any]] {
                for obj in objects {
                    if let id = obj["objectId"] as? String, let cat = obj["category"] as? String {
                        map[id] = cat
                    }
                }
            }
        } catch {
            print("Failed to load safe_decor_parts.json: \(error)")
        }
        return map
    }
    
    static func addVec(_ a: [Double], _ b: [Double]) -> [Double] {
        return [a[0] + b[0], a[1] + b[1], a[2] + b[2]]
    }
    
    static func applyDecorator(donorBase: [String: Any], targetBase: inout [String: Any]) throws -> String {
        let objectToCategory = loadSafeCategories()
        var log = ""
        
        guard let donorObjects = donorBase["Objects"] as? [[String: Any]],
              let targetObjects = targetBase["Objects"] as? [[String: Any]] else {
            throw NSError(domain: "CorvetteLogic", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid base objects array."])
        }
        
        var anchors: [[String: Any]] = []
        var tables: [[String: Any]] = []
        
        for (i, obj) in targetObjects.enumerated() {
            let oid = (obj["ObjectID"] as? String ?? "").uppercased()
            let pos = obj["Position"] as? [Double] ?? []
            
            if INTERIOR_ANCHOR_IDS.contains(oid), pos.count == 3 {
                var a = obj
                a["objectIndex"] = i
                anchors.append(a)
            }
            
            if TABLE_KEYWORDS.contains(where: { oid.contains($0) }), pos.count == 3 {
                var t = obj
                t["objectIndex"] = i
                tables.append(t)
            }
        }
        
        if anchors.isEmpty {
            throw NSError(domain: "CorvetteLogic", code: 2, userInfo: [NSLocalizedDescriptionKey: "No interior anchors found in target base."])
        }
        
        var grouped: [String: [[String: Any]]] = [:]
        for obj in donorObjects {
            if let oid = obj["ObjectID"] as? String, let cat = objectToCategory[oid] {
                grouped[cat, default: []].append(obj)
            }
        }
        
        var additions: [[String: Any]] = []
        
        for (category, count) in TARGET_ADDITIONS {
            if SKIPPED_CATEGORIES.contains(category) { continue }
            
            guard let candidates = grouped[category], !candidates.isEmpty else {
                log += "Category '\(category)' skipped: no donor candidates.\n"
                continue
            }
            
            guard let surfaceType = CATEGORY_TO_SURFACE[category] else { continue }
            
            if surfaceType == "table" && tables.isEmpty {
                log += "Category '\(category)' skipped: no table surfaces detected.\n"
                continue
            }
            
            let slots = SLOTS[surfaceType] ?? [[0.0, 0.0, 0.0]]
            
            for i in 0..<count {
                var newObj = candidates[i % candidates.count]
                newObj["Timestamp"] = Int(Date().timeIntervalSince1970)
                let offset = slots[i % slots.count]
                
                if surfaceType == "table" {
                    let table = tables[i % tables.count]
                    if let tPos = table["Position"] as? [Double] {
                        newObj["Position"] = addVec(tPos, offset)
                    }
                } else {
                    let allowedIds = CATEGORY_ANCHOR_FILTER[category] ?? INTERIOR_ANCHOR_IDS
                    var allowedAnchors = anchors.filter { allowedIds.contains($0["ObjectID"] as? String ?? "") }
                    if allowedAnchors.isEmpty { allowedAnchors = anchors }
                    let anchor = allowedAnchors[i % allowedAnchors.count]
                    if let aPos = anchor["Position"] as? [Double] {
                        newObj["Position"] = addVec(aPos, offset)
                    }
                }
                additions.append(newObj)
            }
        }
        
        var newTargetObjects = targetObjects
        newTargetObjects.append(contentsOf: additions)
        targetBase["Objects"] = newTargetObjects
        
        log += "Successfully generated and appended \(additions.count) new decor items!\n"
        return log
    }
}
