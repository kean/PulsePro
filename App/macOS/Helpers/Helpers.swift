// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import Foundation
import PulseCore
import CoreData

extension URL {
    static var library: URL {
        let url = Files.urls(for: .libraryDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: "/dev/null")
        Files.createDirectoryIfNeeded(at: url)
        return url
    }
}

func stringPrecise(from timeInterval: TimeInterval) -> String {
    let ti = Int(timeInterval)
    let ms = Int((timeInterval.truncatingRemainder(dividingBy: 1)) * 1000)
    let seconds = ti % 60
    let minutes = (ti / 60) % 60
    let hours = (ti / 3600)
    
    if hours >= 1 {
        return String(format: "%0.2d:%0.2d:%0.2d.%0.3d",hours,minutes,seconds,ms)
    } else {
        return String(format: "%0.2d:%0.2d.%0.3d",minutes,seconds,ms)
    }
}

extension LoggerNetworkRequestEntity {
    var isSuccess: Bool {
        guard let state = State(rawValue: requestState) else {
            if errorCode != 0 {
                return false
            } else if statusCode != 0, !(200..<400).contains(statusCode) {
                return false
            } else {
                return true
            }
        }
        return state == .success
    }
}
