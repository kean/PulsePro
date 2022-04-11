// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import Cocoa
import PulseCore
import SwiftUI
import Combine

final class AppRouter {
    static let shared = AppRouter()
    
    static let scheme = "com-github-kean-pulse"
    static let host = "pulse.app"
        
    func openMainView(client: RemoteLoggerClient) {
        var components = URLComponents()
        components.scheme = AppRouter.scheme
        components.host = AppRouter.host
        components.path = AppRouterPath.remoteClientMainView.rawValue
        components.queryItems = [
            .init(name: "clientId", value: client.id.raw)
        ]
        open(components)
    }
    
    func openDetails(view: AnyView) {
        ExternalEvents.open = view
        
        var components = URLComponents()
        components.scheme = AppRouter.scheme
        components.host = AppRouter.host
        components.path = AppRouterPath.detailsView.rawValue
        open(components)
    }
        
    private func open(_ components: URLComponents) {
        guard let url = components.url else {
            return assertionFailure("Failed to instantiate URL from components: \(components)")
        }
        NSWorkspace.shared.open(url)
    }
}

enum AppRouterPath: String {
    case detailsView = "/open-details"
    case remoteClientMainView = "/open-remote-client"
}

extension URL {
    var queryItems: [String: String] {
        guard let queryItems = URLComponents(url: self, resolvingAgainstBaseURL: false)?.queryItems else {
            return [:]
        }
        var map: [String: String] = [:]
        for item in queryItems {
            map[item.name] = item.value
        }
        return map
    }
}

struct ExternalEvents {
    /// - warning: Don't use it, it's used internally.
    static var open: AnyView?
}
