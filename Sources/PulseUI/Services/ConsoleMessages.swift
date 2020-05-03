// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import Foundation
import Pulse

public struct ConsoleMessages: RandomAccessCollection {
    private let messages: [MessageEntity]

    public init(messages: [MessageEntity]) {
        self.messages = messages
    }

    public typealias Index = Int

    public var startIndex: Index { return messages.startIndex }
    public var endIndex: Index { return messages.endIndex }
    public func index(after i: Index) -> Index { i + 1 }

    public subscript(index: Index) -> MessageEntity {
        return messages[index]
    }
}
