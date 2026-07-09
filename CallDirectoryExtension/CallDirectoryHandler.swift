import Foundation
import CallKit

class CallDirectoryHandler: CXCallDirectoryProvider {

    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        context.delegate = self
        addBlockingEntries(to: context)
        context.completeRequest()
    }

    private func addBlockingEntries(to context: CXCallDirectoryExtensionContext) {
        let prefix: Int64 = 911_409_000_000
        let count: Int64 = 1_000_000
        var number = prefix
        let end = prefix + count - 1
        while number <= end {
            context.addBlockingEntry(withNextSequentialPhoneNumber: CXCallDirectoryPhoneNumber(number))
            number += 1
        }
    }
}

extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {
    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {
        print("Call Directory request failed: \(error)")
    }
}
