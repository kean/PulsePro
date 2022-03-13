//
//  TextSearchToolbar.swift
//  Pulse Pro
//
//  Created by Alexander Grebenyuk on 10/13/21.
//  Copyright © 2021 kean. All rights reserved.
//

import Foundation
import SwiftUI

struct TextSearchToolbar: View {
    @ObservedObject var model: TextSearchViewModel
    
    var body: some View {
        HStack {
            Spacer()
            Text(model.matches.isEmpty ?  "Found: 0" : "Found: \(model.selectedMatchIndex+1)/\(model.matches.count)")
                .font(Font.body.monospacedDigit())
                .foregroundColor(.secondary)
                .padding(.trailing, 6)
            HStack(spacing: 6) {
                Button(action: model.previousMatch) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(model.matches.isEmpty)
                Button(action: model.nextMatch) {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(model.matches.isEmpty)
            }
            StringSearchOptionsMenu(options: $model.searchOptions)
                .menuStyle(BorderlessButtonMenuStyle())
                .fixedSize()
                .padding(.trailing, 6)
        }.frame(height: 34)
    }
}
