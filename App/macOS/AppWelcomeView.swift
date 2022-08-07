// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import CoreData
import Combine

struct AppWelcomeView: View {
    let buttonOpenDocumentTapped: () -> Void
    let openDocument: (URL) -> Void
    private let recent = getRecentDocuments()
    
    private var hasDocuments: Bool {
        !recent.isEmpty
    }
    
    var body: some View {
        HStack(spacing: 0) {
            welcomeView
            sidebar
        }
        .navigationTitle("Console")
        .navigationSubtitle("Welcome")
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                ConsoleToolbarModePickerView(viewModel: .init()).disabled(true)
            }
            ToolbarItem {
                Spacer()
            }
            ToolbarItemGroup(placement: .automatic) {
                SearchBar(title: "Search", text: .constant(""), onEditingChanged: { _ in }, onReturn: {})
                    .frame(width: 95)
                    .disabled(true)
                Button(action: {}) {
                    Image(systemName: "exclamationmark.octagon")
                }.disabled(true)
                Button(action: {}, label: {
                    Image(systemName: "line.horizontal.3.decrease.circle")
                }).disabled(true)
                Button(action: {}, label: {
                    Image(systemName: "square.split.2x1")
                }).disabled(true)
            }
        }
    }

    private var welcomeView: some View {
        VStack(spacing: 0) {
            Image("512")
                .resizable()
                .frame(width: 256, height: 256)
            Text("Welcome to Pulse Pro")
                .font(.system(size: 34, weight: .regular))
            Spacer().frame(height: 10)
            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–")" + (isDemoVersion ? " (Trial)" : ""))
                .foregroundColor(.secondary)
            Spacer().frame(height: 10)
        }
        .frame(minWidth: 320, maxHeight: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
        .padding(8)
    }
    
    private var sidebar: some View {
        VStack(spacing: 20) {
            quickActionsView
            recentDocumentsList
        }
        .padding(.leading, 40)
        .frame(minWidth: 360, idealWidth: 360, maxWidth: 360, minHeight: 500, idealHeight: 600, maxHeight: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
    }
    
    private var recentDocumentsList: some View {
        VStack(alignment: .leading) {
            if !recent.isEmpty {
                Section(header: Text("Recently Open")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(EdgeInsets(top: 1, leading: 0, bottom: 1, trailing: 0))) {
                    ForEach(getRecentDocuments(), id: \.self) { SuggestedDocumentView(openDocument: openDocument, url: $0) }
                }
            }
        }
        .overlay(recentDocumentsPlaceholder, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
    }
    
    @ViewBuilder
    private var recentDocumentsPlaceholder: some View {
        if hasDocuments{
            EmptyView()
        } else {
            Text("No Recent Documents")
                .font(.title2)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(EdgeInsets(top: 1, leading: 0, bottom: 1, trailing: 10))
        }
    }
    
    @ViewBuilder
    private var quickActionsView: some View {
        VStack(alignment: .leading, spacing: 0) {
            QuickActionView(title: "Open Document", details: "View a previously shared documents with logs", image: "doc", action: buttonOpenDocumentTapped)
        }
    }
}

private struct SuggestedDocumentView: View {
    let openDocument: (URL) -> Void
    let url: URL
    
    var body: some View {
        Button(action: { openDocument(url) }, label: {
            let path = url.path.replacingOccurrences(of: "/Users/\(NSUserName())", with: "~", options: .anchored, range: nil)
            HStack {
                Image(systemName: "doc")
                    .font(.system(size: 18))
                VStack(alignment: .leading, spacing: 4) {
                    Text(url.lastPathComponent)
                        .lineLimit(1)
                    Text(path)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        })
            .buttonStyle(PlainButtonStyle())
            .padding(EdgeInsets(top: 1, leading: 0, bottom: 1, trailing: 10))
    }
}

private struct QuickActionView: View {
    let title: String
    let details: String
    let image: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: image)
                        .font(.system(size: 24))
                        .foregroundColor(Color.accentColor)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                        Text(details)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(EdgeInsets(top: 3, leading: 0, bottom: 3, trailing: 10))
    }
}

private func getRecentDocuments() -> [URL] {
    Array(NSDocumentController.shared.recentDocumentURLs.prefix(5))
}

private extension URL {
    var creationDate: Date {
        ((try? FileManager.default.attributesOfItem(atPath: absoluteString)[.creationDate]) as? Date) ?? Date.distantPast
    }
}

struct AppWelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        AppWelcomeView(buttonOpenDocumentTapped: {}, openDocument: { _ in })
            .frame(width: 800, height: 460)
    }
}
