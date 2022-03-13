// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import Cocoa
import PulseCore
import SwiftUI
import Combine

final class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    // Remote logging
    @AppStorage("remote_logging-custom-port") var port: String = ""
    @AppStorage("remote_logging-custom-name") var serviceName: String = ""
    
    // UI preferences
    @AppStorage("console-visible-columns") var consoleVisibleColumnns = String(ConsoleColumn.defaultSelection.map({ $0.rawValue }).joined(separator: ","))
    
    var mappedConsoleVisibleColumns: Set<ConsoleColumn> {
        get {
            Set(consoleVisibleColumnns.split(separator: ",").compactMap { ConsoleColumn(rawValue: String($0)) })
        }
        set {
            consoleVisibleColumnns = newValue.map { $0.rawValue }.joined(separator: ",")
        }
    }
    
    @AppStorage("networkListVisibleColumns") var networkListVisibleColumns = String(NetworkListColumn.defaultSelection.map({ $0.rawValue }).joined(separator: ","))
    
    var mappedNetworkListVisibleColumns: Set<NetworkListColumn> {
        get {
            Set(networkListVisibleColumns.split(separator: ",").compactMap { NetworkListColumn(rawValue: String($0)) })
        }
        set {
            networkListVisibleColumns = newValue.map { $0.rawValue }.joined(separator: ",")
        }
    }
    
    @AppStorage("messageFontSize") var messageFontSize = Constants.ResponseViewer.defaultFontSize
    @AppStorage("viewerFontSize") var viewerFontSize = Constants.ResponseViewer.defaultCodeFontSize
    @AppStorage("storyFontSize") var storyFontSize = Constants.ResponseViewer.defaultFontSize
    @AppStorage("headersFontSize") var headersFontSize = Constants.ResponseViewer.defaultCodeFontSize
    @AppStorage("cURLFontSize") var cURLFontSize = Constants.ResponseViewer.defaultCodeFontSize
    
    @AppStorage("isStoryNetworkExpanded") var isStoryNetworkExpanded = false
    @AppStorage("isStoryCompactModeEnabled") var isStoryCompactModeEnabled = true
    @AppStorage("isStoryReducedCount") var isStoryReducedCount = true
}

enum Constants {
    enum ResponseViewer {
        static let defaultCodeFontSize = 12
        static let defaultFontSize = 13
        static let minFontSize = 9
        static let maxFontSize = 30
        static let defaultLineHeight = 19
        static func lineHeight(for fontSize: Int) -> CGFloat {
            CGFloat(fontSize + (defaultLineHeight - defaultFontSize))
        }
    }
}


extension UserDefaults {
    @objc dynamic var textViewLineNumbersEnabledForMessage: Bool { bool(forKey: "textViewLineNumbersEnabledForMessage") }
    @objc dynamic var textViewLineNumbersEnabledForResponse: Bool { bool(forKey: "textViewLineNumbersEnabledForResponse") }
    @objc dynamic var textViewLineNumbersEnabledForHeaders: Bool { bool(forKey: "textViewLineNumbersEnabledForHeaders") }
    @objc dynamic var textViewLineNumbersEnabledForStory: Bool { bool(forKey: "textViewLineNumbersEnabledForStory") }
    @objc dynamic var textViewLineNumbersEnabledForCURL: Bool { bool(forKey: "textViewLineNumbersEnabledForCURL") }
    
    @objc dynamic var messageFontSize: Int { integer(forKey: "messageFontSize") }
    @objc dynamic var viewerFontSize: Int { integer(forKey: "viewerFontSize") }
    @objc dynamic var storyFontSize: Int { integer(forKey: "storyFontSize") }
    @objc dynamic var headersFontSize: Int { integer(forKey: "headersFontSize") }
    @objc dynamic var cURLFontSize: Int { integer(forKey: "cURLFontSize") }

    @objc dynamic var isStoryNetworkExpanded: Bool { bool(forKey: "isStoryNetworkExpanded") }
    @objc dynamic var isStoryCompactModeEnabled: Bool { bool(forKey: "isStoryCompactModeEnabled") }
    @objc dynamic var isStoryReducedCount: Bool { bool(forKey: "isStoryReducedCount") }
}

extension RichTextViewContentType {
    var fontSizeBinding: Binding<Int> {
        switch self {
        case .response: return AppSettings.shared.$viewerFontSize
        case .headers: return  AppSettings.shared.$headersFontSize
        case .story: return AppSettings.shared.$storyFontSize
        case .message: return AppSettings.shared.$messageFontSize
        case .curl: return AppSettings.shared.$cURLFontSize
        }
    }
    
    var fontSizeKeyPath: KeyPath<UserDefaults, Int> {
        switch self {
        case .response: return \UserDefaults.viewerFontSize
        case .headers: return  \UserDefaults.headersFontSize
        case .story: return \UserDefaults.storyFontSize
        case .message: return \UserDefaults.messageFontSize
        case .curl: return \UserDefaults.cURLFontSize
        }
    }
    
    var lineNumbersKeyPath: KeyPath<UserDefaults, Bool> {
        switch self {
        case .response: return \UserDefaults.textViewLineNumbersEnabledForResponse
        case .headers: return  \UserDefaults.textViewLineNumbersEnabledForHeaders
        case .story: return \UserDefaults.textViewLineNumbersEnabledForStory
        case .message: return \UserDefaults.textViewLineNumbersEnabledForMessage
        case .curl: return \UserDefaults.textViewLineNumbersEnabledForCURL
        }
    }
}
