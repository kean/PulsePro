// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import Foundation
import Pulse

struct ConsoleMessages: RandomAccessCollection {
    private let messages: [MessageEntity]

    init(messages: [MessageEntity]) {
        self.messages = messages
    }

    typealias Index = Int

    var startIndex: Index { return messages.startIndex }
    var endIndex: Index { return messages.endIndex }
    func index(after i: Index) -> Index { i + 1 }

    subscript(index: Index) -> MessageEntity {
        return messages[index]
    }
}
