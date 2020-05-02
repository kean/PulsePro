// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import CoreData
import Pulse

struct ConsoleMessageViewModel {
    let title: String
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

    init(title: String, text: String, style: ConsoleMessageStyle) {
        self.title = title
        self.text = text
        self.style = style
    }

    init(message: MessageEntity) {
        let time = ConsoleMessageViewModel.timeFormatter
            .string(from: message.created)
        let category = message.category == "default" ? "" : ":\(message.category)"
        self.title = "\(time) | \(message.system)\(category)"
        self.text = message.text
        self.style = ConsoleMessageStyle.make(level: Logger.Level(rawValue: message.level) ?? .debug)
    }
}
