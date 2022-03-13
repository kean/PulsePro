// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import SwiftUI

struct RemoteLoggerClientStatusView: View {
    @ObservedObject var client: RemoteLoggerClient
    
    var body: some View {
        overlay
            .background(Color.clear)
            .padding(4)
    }
    
    private var overlay: some View {
        HStack(alignment: .lastTextBaseline, spacing: 0) {
            Image(systemName: "network")
                .background(iconBackground)
                .padding(.trailing, 8)
            VStack(alignment: .leading) {
                (Text(client.info.deviceInfo.name) + Text(client.preferredSuffix ?? "")
                    .foregroundColor(Color.secondary))
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            if !client.isConnected {
                Image(systemName: "bolt.horizontal.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .padding(EdgeInsets(top: 5, leading: 6, bottom: 5, trailing: 6))
        .frame(minWidth: 100, idealWidth: 150)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
        .clipped()
    }
    
    @ViewBuilder
    private var iconBackground: some View {
        if client.isConnected && !client.isPaused {
            LoaderView(color: NSColor.label.withAlphaComponent(0.1), duration: 1.2)
                .frame(width: 100, height: 100)
        }
    }
}

struct RemoteLoggerTooglePlayButton: View {
    @ObservedObject var client: RemoteLoggerClient
    
    var body: some View {
        Button(action: client.togglePlay, label: {
            Image(systemName: client.isPaused ? "play.fill" : "pause.fill")
        }).help(client.isPaused ? "Start Streaming (⇧⌘S)" : "Stop Streaming (⇧⌘S)")
    }
}

struct RemoteLoggerClientStatusViewPro_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RemoteLoggerClientStatusView(client: .mock())
                .previewLayout(.fixed(width: 200, height: 400))
        }
    }
}
