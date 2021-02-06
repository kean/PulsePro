// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import Foundation

struct DurationFormatter {
    static func string(from timeInterval: TimeInterval) -> String {
        if timeInterval < 0.95 {
            return String(format: "%.1fms", timeInterval * 1000)
        }
        if timeInterval < 200 {
            return String(format: "%.1fs", timeInterval)
        }
        let minutes = timeInterval / 60
        if minutes < 60 {
            return String(format: "%.1fmin", minutes)
        }
        let hours = timeInterval / (60 * 60)
        return String(format: "%.1fh", hours)
    }
}
