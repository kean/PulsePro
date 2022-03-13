import Foundation
import PulseCore
import CoreData

final class NetworkMessagesTextSearch {
    private var requests: [LoggerNetworkRequestEntity] = []
    private var searchIndex: [(NSManagedObjectID, String)]?
    private let lock = NSLock()

    func replace(_ requests: [LoggerNetworkRequestEntity]) {
        self.requests = requests
        self.searchIndex = nil
    }

    func search(term: String, options: StringSearchOptions) -> [ConsoleMatch] {
        let searchIndex = getSearchIndex()
        let indices = searchIndex.indices
        let iterations = indices.count > 100 ? 8 : 1
        var allMatches: [[Int]] = Array(repeating: [], count: iterations)
        let lock = NSLock()
        DispatchQueue.concurrentPerform(iterations: iterations) { index in
            let start = index * indices.count / iterations
            let end = (index + 1) * indices.count / iterations

            var matches = [Int]()
            for matchIndex in start..<end {
                let messageIndex = indices[matchIndex]
                if searchIndex[messageIndex].1.range(of: term, options: .init(options), range: nil, locale: nil) != nil {
                    matches.append(messageIndex)
                }
            }

            lock.lock()
            allMatches[index] = matches
            lock.unlock()
        }
        return allMatches.flatMap { $0 }.map { ConsoleMatch(index: $0, objectID: searchIndex[$0].0) }
    }

    // It's needed for two reasons:
    // - Making sure `concurrentPerform` accesses data in a thread-safe way
    // - It's faster than accessing Core Data backed array (for some reason)
    private func getSearchIndex() -> [(NSManagedObjectID, String)] {
        if let searchIndex = self.searchIndex {
            return searchIndex
        }
        let searchIndex = requests.map { ($0.objectID, $0.message?.text ?? "") }
        self.searchIndex = searchIndex
        return searchIndex
    }
}
