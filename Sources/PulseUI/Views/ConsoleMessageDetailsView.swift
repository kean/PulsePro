// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import Pulse

struct ConsoleMessageDetailsView: View {
    let model: ConsoleMessageDetailsViewModel
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        VStack {
            tags
            Text(model.text)
        }
    }
    
    private var tags: some View {
        VStack {
            ForEach(model.tags, id: \.title) { tag in
                HStack {
                    Text(tag.title)
                        .font(.caption)
                        .foregroundColor(self.model.style.titleColor)
                    Text(tag.value)
                        .font(.caption)
                        .bold()
                        .foregroundColor(self.model.style.titleColor)
                }
            }
        }
        .padding()
        .background(model.style.backgroundColor.opacity(colorScheme == .dark ? 0.1 : 0.05))
    }
}
