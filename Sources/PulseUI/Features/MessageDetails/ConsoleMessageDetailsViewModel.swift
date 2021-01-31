// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import CoreData
import Pulse
import Combine
import Logging

final class ConsoleMessageDetailsViewModel {
    let tags: [ConsoleMessageTagViewModel]
    let text: String
    let style: ConsoleMessageStyle

    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()

    init(tags: [ConsoleMessageTagViewModel], text: String, style: ConsoleMessageStyle) {
        self.tags = tags
        self.text = text
        self.style = style
    }

    init(message: MessageEntity) {
        self.tags = [
            ConsoleMessageTagViewModel(
                title: "Date",
                value: ConsoleMessageViewModel.timeFormatter
                    .string(from: message.createdAt)
            ),
            ConsoleMessageTagViewModel(
                title: "Label",
                value: message.label == "default" ? "n/a" : message.label
            ),
        ]
        self.text = message.text
        self.style = ConsoleMessageStyle.make(level: Logger.Level(rawValue: message.level) ?? .debug)
    }

    func prepareForSharing() -> Any {
        return text
    }
}

struct ConsoleMessageTagViewModel {
    let title: String
    let value: String
}
