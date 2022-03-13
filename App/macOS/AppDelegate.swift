// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import Cocoa
import SwiftUI
import CryptoKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    
    static private(set) var shared: AppDelegate?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
                
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == nil {
            if RemoteLoggerServer.shared.isEnabled {
                RemoteLoggerServer.shared.enable()
            }
        }
    }
}

// MARK: Trial

let isDemoVersion = false

private let userDefaultsKey = "7f158dee-d7e0-4cbf-bbca-01f28f36bb08"

var isTrialExpired: Bool {
    guard isDemoVersion else {
        return false
    }
    
    let installationDate: Date
    if let string = UserDefaults.standard.string(forKey: userDefaultsKey),
       let data = Data(base64Encoded: string),
       let date = try? JSONDecoder().decode(Date.self, from: data) {
        installationDate = date
    } else {
        installationDate = Date()
        let data = try! JSONEncoder().encode(installationDate)
        UserDefaults.standard.set(data.base64EncodedString(), forKey: userDefaultsKey)
    }
    
    return Date().timeIntervalSince(installationDate) > (86400 * 30)
}
