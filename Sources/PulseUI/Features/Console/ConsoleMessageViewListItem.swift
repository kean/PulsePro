// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI
import CoreData
import Pulse
import Combine

#if os(iOS)
import UIKit

// TODO: create a ViewModel for a share sheet
struct ConsoleMessageViewListItem: View {
    let message: MessageEntity

    @Binding var searchCriteria: ConsoleSearchCriteria
    @State private var isShowingShareSheet = false

    var body: some View {
        ConsoleMessageView(model: .init(message: message))
            .contextMenu {
                Button(action: {
                    self.isShowingShareSheet = true
                }) {
                    Text("Share")
                    Image(uiImage: UIImage(systemName: "square.and.arrow.up", withConfiguration: UIImage.SymbolConfiguration(pointSize: 44, weight: .black, scale: .medium))!)
                }
                Button(action: {
                    UIPasteboard.general.string = self.message.text
                }) {
                    Text("Copy Message")
                    Image(uiImage: UIImage(systemName: "doc.on.doc", withConfiguration: UIImage.SymbolConfiguration(pointSize: 44, weight: .black, scale: .medium))!)
                }
                Button(action: {
                    let filter = ConsoleSearchFilter(text: self.message.label, kind: .label, relation: .equals)
                    self.searchCriteria.filters.append(filter)
                }) {
                    Text("Focus \'\(message.label)\'")
                    Image(systemName: "eye")
                }
                Button(action: {
                    let filter = ConsoleSearchFilter(text: self.message.label, kind: .label, relation: .doesNotEqual)
                    self.searchCriteria.filters.append(filter)
                }) {
                    Text("Hide \'\(message.label)\'")
                    Image(systemName: "eye.slash")
                }.foregroundColor(.red)
        }
        .sheet(isPresented: $isShowingShareSheet) {
            ShareView(activityItems: [self.message.text])
        }
    }
}

#endif
