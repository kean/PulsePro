// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI

struct KeyValueGridView: View {
    @Environment(\.horizontalSizeClass) var sizeClass: UserInterfaceSizeClass?
    let items: [KeyValueSectionViewModel]

    var body: some View {
        VStack {
            if sizeClass == .regular, items.count > 1 {
                let rows = items.chunked(into: 2).enumerated().map {
                    Row(index: $0, items: $1)
                }
                ForEach(rows, id: \.index) { row in
                    HStack {
                        ForEach(row.items, id: \.title) { item in
                            VStack {
                                KeyValueSectionView(model: item)
                                Spacer()
                                    .layoutPriority(1)
                            }
                        }
                    }
                }
            } else {
                ForEach(items, id: \.title) {
                    KeyValueSectionView(model: $0)
                }
            }
        }
    }
}

private struct Row {
    let index: Int
    let items: [KeyValueSectionViewModel]
}
