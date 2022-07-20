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
    @ObservedObject var viewModel: TextSearchViewModel
    
    var body: some View {
        HStack {
            Spacer()
            Text(viewModel.matches.isEmpty ?  "Found: 0" : "Found: \(viewModel.selectedMatchIndex+1)/\(viewModel.matches.count)")
                .font(Font.body.monospacedDigit())
                .foregroundColor(.secondary)
                .padding(.trailing, 6)
            HStack(spacing: 6) {
                Button(action: viewModel.previousMatch) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(viewModel.matches.isEmpty)
                Button(action: viewModel.nextMatch) {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(viewModel.matches.isEmpty)
            }
            StringSearchOptionsMenu(options: $viewModel.searchOptions)
                .menuStyle(BorderlessButtonMenuStyle())
                .fixedSize()
                .padding(.trailing, 6)
        }.frame(height: 34)
    }
}
