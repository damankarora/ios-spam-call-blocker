import Foundation
import CallKit

class CallDirectoryHandler: CXCallDirectoryProvider {

    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        context.delegate = self
        addBlockingEntries(to: context)
        context.completeRequest()
    }

    private func addBlockingEntries(to context: CXCallDirectoryExtensionContext) {
        let intervals = BlockListStore.load()
            .compactMap { range -> ClosedRange<Int64>? in
                guard let start = range.startNumber, let end = range.endNumber else { return nil }
                return start...end
            }
            .sorted { $0.lowerBound < $1.lowerBound }

        // CallKit requires strictly ascending, non-repeating numbers or it silently discards
        // the whole batch, so overlapping ranges must be clipped rather than added as-is.
        var lastAdded: Int64?
        for interval in intervals {
            var number = interval.lowerBound
            if let last = lastAdded, number <= last {
                number = last + 1
            }
            while number <= interval.upperBound {
                context.addBlockingEntry(withNextSequentialPhoneNumber: CXCallDirectoryPhoneNumber(number))
                lastAdded = number
                number += 1
            }
        }
    }
}

extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {
    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {
        print("Call Directory request failed: \(error)")
    }
}
