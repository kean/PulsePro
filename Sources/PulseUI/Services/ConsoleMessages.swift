// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import Foundation
import Pulse

public struct ConsoleMessages: RandomAccessCollection {
    private let messages: [LoggerMessage]

    public init(messages: [LoggerMessage]) {
        self.messages = messages
    }

    public typealias Index = Int

    public var startIndex: Index { return messages.startIndex }
    public var endIndex: Index { return messages.endIndex }
    public func index(after i: Index) -> Index { i + 1 }

    public subscript(index: Index) -> LoggerMessage {
        return messages[index]
    }
}
