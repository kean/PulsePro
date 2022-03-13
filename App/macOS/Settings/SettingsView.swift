// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import CoreData
import PulseCore
import Combine
import Network

private let totalWidth: CGFloat = 540
private let totalPadding: CGFloat = 32

struct SettingsView: View {
    private enum Tabs: Hashable {
        case general, remote
    }
    var body: some View {
        TabView {
//            GeneralSettingsView()
//                .tabItem {
//                    Label("General", systemImage: "gear")
//                }
//                .tag(Tabs.general)
            RemoteLoggingSettingsView()
                .tabItem {
                    Label("Remote Logging", systemImage: "network")
                }
                .tag(Tabs.remote)
        }
        .padding(totalPadding)
        .frame(width: totalWidth, height: 360)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("showPreview") private var showPreview = true
    @AppStorage("fontSize") private var fontSize = 12.0

    var body: some View {
        Form {
            Toggle("Show Previews", isOn: $showPreview)
            Slider(value: $fontSize, in: 9...96) {
                Text("Font Size (\(fontSize, specifier: "%.0f") pts)")
            }
        }
        .padding(totalPadding)
        .frame(width: totalWidth, height: 120)
    }
}

struct RemoteLoggingSettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var server = RemoteLoggerServer.shared
    @ObservedObject var model = RemoteLoggerViewModel.shared
        
    var preferences: Preferences {
        Preferences()
    }
    
    var body: some View {
        Form {
            sectionRemoteLogging
            
            preferences.divider()
                
            preferences.textField(title: "Port", placeholder: "Any", width: 70, text: settings.$port)
            preferences.textField(title: "Service Name", placeholder: "\(Host.current().localizedName ?? "Default")", width: 140, text: settings.$serviceName)

            Spacer()
            HStack {
                RemogeLoggingStatusView()
                Spacer()
                Button("Apply Settings", action: server.restart)
                    .fixedSize()
            }
        }
        .padding(totalPadding)
        .frame(width: totalWidth, height: 360)
    }
    
    @ViewBuilder
    private var sectionRemoteLogging: some View {
        preferences.toggle(title: "Remote logging", isOn: $model.isRemoteLoggingEnabled)
        preferences.caption(text: "Listen to the apps on the local network. Go to the Pulse Settings in your app, enable remote logging, and select a server.")
    }
}

private struct RemogeLoggingStatusView: View {
    @ObservedObject var server = RemoteLoggerServer.shared
    
    var body: some View {
        status
            .frame(maxWidth: 280)
    }
    
    @ViewBuilder
    private var status: some View {
        if let error = server.listenerSetupError {
            makeStatus(color: .red, text: error.localizedDescription)
        } else {
            switch server.listenerState {
            case .cancelled:
                makeStatus(color: .gray, text: "Disabled")
            case .failed(let error), .waiting(let error):
                makeStatus(color: .red, text: error.localizedDescription)
            case .setup:
                makeStatus(color: .yellow, text: "Setting Up")
            case .ready:
                makeStatus(color: .green, text: "Accepting Connections")
            @unknown default:
                makeStatus(color: .gray, text: "Disabled")
            }
        }
    }
    
    private func makeStatus(color: Color, text: String) -> some View {
        HStack {
            makeCircle(color: color)
            Text(text)
                .lineLimit(2)
            Spacer()
        }
    }
    
    private func makeCircle(color: Color) -> some View {
        Circle()
            .frame(width: 10, height: 10)
            .foregroundColor(color)
    }
}

struct Preferences {
    var spacing: CGFloat = 8
    var offset: CGFloat = 110
    var verticalSpacing: CGFloat = 32
    
    func divider() -> some View {
        Divider()
            .frame(height: verticalSpacing, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
    }
    
    func textField(title: String, placeholder: String, width: CGFloat, text: Binding<String>) -> some View {
        HStack(spacing: spacing) {
            Text(title + ":")
                .frame(width: offset, alignment: .trailing)
            TextField(placeholder, text: text)
                .frame(width: width)
            Spacer()
        }
    }
    
    func toggle(title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: spacing) {
            Text("")
                .frame(width: offset, alignment: .trailing)
            Toggle(title, isOn: isOn)
            Spacer()
        }
    }
    
    func caption(text: String) -> some View {
        HStack(spacing: spacing) {
            Text("")
                .frame(width: offset, alignment: .trailing)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
    
    func button(title: String, action: @escaping () -> Void) -> some View {
        HStack(spacing: spacing) {
            Text("")
                .frame(width: offset, alignment: .trailing)
            Button(title, action: action)
            Spacer()
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        
        SettingsView()
    }
}

