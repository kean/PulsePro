// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import Cocoa
import Pulse
import SwiftUI
import Combine

struct RouterView: View {
    @StateObject var viewModel = RouterViewModel()
        
    var body: some View {
        contents
            .onOpenURL(perform: viewModel.open(url:))
    }
    
    @ViewBuilder
    private var contents: some View {
        if let client = self.viewModel.client {
            MainViewPro(client: client)
        } else if let detailsView = viewModel.detailsView {
            detailsView
        } else {
            PlaceholderView(imageName: "exclamationmark.circle.fill", title: "Something went wrong", subtitle: nil)
                .frame(width: 1000, height: 600)
        }
    }
}

final class RouterViewModel: ObservableObject {
    @Published var client: RemoteLoggerClient?
    @Published var detailsView: AnyView?
    
    func open(url: URL) {
        switch AppRouterPath(rawValue: url.path) {
        case .detailsView:
            detailsView = ExternalEvents.open
        case .remoteClientMainView:
            if let clientId = url.queryItems["clientId"].map(RemoteLoggerClientId.init),
               let client = RemoteLoggerServer.shared.clients[clientId] {
                self.client = client
            }
        default:
            pulseLog("Unexpected URL \(url)")
            break
        }
    }
}
