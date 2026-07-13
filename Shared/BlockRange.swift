import Foundation

struct BlockRange: Identifiable, Codable, Equatable {
    var id = UUID()
    var countryCode: String
    var prefix: String
    var wildcardDigits: Int

    var isValid: Bool {
        !countryCode.isEmpty
            && !prefix.isEmpty
            && (countryCode + prefix).allSatisfy(\.isNumber)
            && (1...6).contains(wildcardDigits)
    }

    /// First number in the range, as CallKit expects it: country code + prefix + zero-filled digits, no "+"/dashes.
    var startNumber: Int64? {
        guard isValid, let base = Int64(countryCode + prefix) else { return nil }
        return base * wildcardMultiplier
    }

    var endNumber: Int64? {
        guard let start = startNumber else { return nil }
        return start + wildcardMultiplier - 1
    }

    var entryCount: Int64 {
        wildcardMultiplier
    }

    private var wildcardMultiplier: Int64 {
        Int64(pow(10.0, Double(wildcardDigits)))
    }

    var displayRange: String {
        "+\(countryCode) \(prefix)" + String(repeating: "X", count: wildcardDigits)
    }
}
