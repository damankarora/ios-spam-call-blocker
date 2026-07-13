import Foundation

enum BlockListStore {
    /// Must match the App Group entitlement on both the app and the extension targets,
    /// otherwise the extension silently reads an empty store and blocks nothing.
    static let appGroupID = "group.com.damankarora.callblocker"
    private static let key = "blockedRanges"

    static let defaultRanges: [BlockRange] = [
        BlockRange(countryCode: "91", prefix: "1409", wildcardDigits: 6)
    ]

    private static var defaults: UserDefaults {
        // Force-unwrapped so a missing/misconfigured App Groups capability fails loudly at launch
        // instead of silently diverging what the app shows from what the extension actually blocks.
        UserDefaults(suiteName: appGroupID)!
    }

    static func load() -> [BlockRange] {
        guard let data = defaults.data(forKey: key),
              let ranges = try? JSONDecoder().decode([BlockRange].self, from: data) else {
            return defaultRanges
        }
        return ranges
    }

    static func save(_ ranges: [BlockRange]) {
        guard let data = try? JSONEncoder().encode(ranges) else { return }
        defaults.set(data, forKey: key)
    }
}
