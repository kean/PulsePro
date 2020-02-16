// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import Foundation
import SwiftUI

struct SearchBar: View {
    let title: String
    @Binding var text: String

    var body: some View {
        HStack {
            #if os(iOS)
            Image(systemName: "magnifyingglass").opacity(0.33)
            #endif
            TextField(title, text: $text)
            #if os(iOS)
            if !text.isEmpty { buttonClear }
            #endif
        }
        .padding(8)
        .background(Color.gray.opacity(0.25))
        .cornerRadius(8)
    }

    #if os(iOS)
    private var buttonClear: some View {
        Button(action: { self.text = "" }) {
            Image(systemName: "xmark.circle.fill")
        }.foregroundColor(Color.gray.opacity(0.25))
    }
    #endif
}

struct SearchBar_Previews: PreviewProvider {
    private struct SearchPreview: View {
        @State private var text: String = ""

        var body: some View {
            SearchBar(title: "Search", text: $text)
        }
    }

    static var previews: some View {
        SearchPreview()
            .previewLayout(.sizeThatFits)
    }
}
