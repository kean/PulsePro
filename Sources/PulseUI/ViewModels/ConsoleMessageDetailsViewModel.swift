// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import CoreData
import Pulse
import Combine

final class ConsoleMessageDetailsViewModel {
    let tags: [ConsoleMessageTagViewModel]
    let text: String
    let style: ConsoleMessageStyle

    #warning("TODO: improve and reuse formatter")
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
                    .string(from: message.created)
            ),
            ConsoleMessageTagViewModel(
                title: "System",
                value: message.system == "default" ? "n/a" : message.category
            ),
            ConsoleMessageTagViewModel(
                title: "Category",
                value: message.category == "default" ? "n/a" : message.category
            )
        ]
        self.text = message.text
        self.style = ConsoleMessageStyle.make(level: Logger.Level(rawValue: message.level) ?? .debug)
    }
}

struct ConsoleMessageTagViewModel {
    let title: String
    let value: String
}
